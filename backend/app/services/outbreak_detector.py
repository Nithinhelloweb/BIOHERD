import math
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional, Tuple
from app.db.models import SeverityLevelEnum


EARTH_RADIUS_KM = 6371.0

# Virulence and transmission weights for endemic livestock diseases
DISEASE_VIRULENCE_WEIGHTS = {
    "Anthrax": 1.0,
    "Haemorrhagic Septicaemia": 0.95,
    "Black Quarter": 0.90,
    "Foot and Mouth Disease": 0.85,
    "Lumpy Skin Disease": 0.80,
    "Peste des Petits Ruminants": 0.80,
    "Bovine Theileriosis": 0.70,
    "Enterotoxemia": 0.65,
    "Brucellosis": 0.60,
    "Bovine Mastitis": 0.45,
}

# Regional weather risk modifiers for Maharashtra agro-climatic zones
DISTRICT_WEATHER_FACTORS = {
    # High humidity / Heavy rainfall zones (HS & FMD high risk)
    "Ratnagiri": 1.3,
    "Sindhudurg": 1.3,
    "Raigad": 1.25,
    "Thane": 1.2,
    "Palghar": 1.2,
    "Kolhapur": 1.25,
    "Satara": 1.15,
    # Central drought-prone / tick-vector zones (Theileriosis, Enterotoxemia, LSD)
    "Solapur": 1.35,
    "Ahmednagar": 1.3,
    "Pune": 1.2,
    "Sangli": 1.2,
    "Beed": 1.25,
    "Osmanabad": 1.25,
    "Latur": 1.2,
    "Jalna": 1.15,
    "Aurangabad": 1.15,
    # Vidarbha high heat & river basin zones
    "Nagpur": 1.15,
    "Amravati": 1.15,
    "Yavatmal": 1.2,
    "Nanded": 1.2,
    "Chandrapur": 1.15,
}


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great-circle distance between two points on the Earth's surface (in kilometers).
    """
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return EARTH_RADIUS_KM * c


def generate_circle_polygon(
    center_lat: float, center_lon: float, radius_km: float, num_points: int = 32
) -> List[List[float]]:
    """
    Generate a GeoJSON Polygon ring [[lon, lat], ...] approximating a circular buffer zone.
    """
    coordinates = []
    angular_dist = radius_km / EARTH_RADIUS_KM
    center_lat_rad = math.radians(center_lat)
    center_lon_rad = math.radians(center_lon)

    for i in range(num_points):
        bearing = (2.0 * math.pi * i) / num_points
        lat_rad = math.asin(
            math.sin(center_lat_rad) * math.cos(angular_dist)
            + math.cos(center_lat_rad) * math.sin(angular_dist) * math.cos(bearing)
        )
        lon_rad = center_lon_rad + math.atan2(
            math.sin(bearing) * math.sin(angular_dist) * math.cos(center_lat_rad),
            math.cos(angular_dist) - math.sin(center_lat_rad) * math.sin(lat_rad),
        )
        coordinates.append([round(math.degrees(lon_rad), 6), round(math.degrees(lat_rad), 6)])

    # Close the polygon ring by repeating the first coordinate
    coordinates.append(coordinates[0])
    return coordinates


def calculate_r0(
    recent_cases_count: int,
    prior_cases_count: int,
    generation_interval_days: float = 7.0,
) -> float:
    """
    Calibrate basic reproduction number (R0) over a 14-day rolling window.
    R0 > 1.0 indicates accelerating transmission outbreak; R0 < 1.0 indicates decaying infection.
    """
    if prior_cases_count <= 0:
        if recent_cases_count == 0:
            return 0.0
        # Novel localized cluster outbreak
        return min(3.5, 1.2 + (recent_cases_count * 0.15))

    ratio = recent_cases_count / prior_cases_count
    # Damped R0 estimation bounded between 0.1 and 4.5
    r0 = round(max(0.1, min(4.5, ratio * 1.1)), 2)
    return r0


def calculate_district_risk_score(
    district_name: str,
    active_cases: int,
    livestock_population: int,
    primary_disease: str = "Foot and Mouth Disease",
    recent_cases_7d: int = 0,
    prior_cases_7d: int = 0,
) -> Dict[str, Any]:
    """
    Calculate multi-parametric District Risk Index (0-100) and epidemiological category.
    """
    pop = max(1000, livestock_population)
    case_density_per_10k = (active_cases / pop) * 10000.0

    virulence = DISEASE_VIRULENCE_WEIGHTS.get(primary_disease, 0.70)
    weather_factor = DISTRICT_WEATHER_FACTORS.get(district_name, 1.0)
    r0 = calculate_r0(recent_cases_7d, prior_cases_7d)

    # Base density component (up to 45 points)
    density_score = min(45.0, case_density_per_10k * 15.0)

    # Transmission velocity component (up to 30 points)
    r0_score = min(30.0, (r0 / 2.0) * 20.0) if r0 > 0 else 0.0

    # Virulence and environmental modifier (up to 25 points)
    environmental_score = min(25.0, 15.0 * virulence * weather_factor)

    raw_score = density_score + r0_score + environmental_score
    risk_score = round(max(5.0, min(100.0, raw_score)), 1)

    if risk_score >= 75.0 or (active_cases >= 10 and r0 >= 1.5):
        severity = SeverityLevelEnum.CRITICAL
    elif risk_score >= 50.0 or active_cases >= 5:
        severity = SeverityLevelEnum.HIGH
    elif risk_score >= 25.0 or active_cases >= 1:
        severity = SeverityLevelEnum.MEDIUM
    else:
        severity = SeverityLevelEnum.LOW

    return {
        "risk_score": risk_score,
        "severity": severity,
        "r0_estimate": r0,
        "case_density_per_10k": round(case_density_per_10k, 2),
        "weather_factor": weather_factor,
        "virulence_factor": virulence,
    }


def detect_spatial_clusters(
    points: List[Dict[str, Any]],
    eps_km: float = 15.0,
    min_samples: int = 2,
) -> List[Dict[str, Any]]:
    """
    Geospatial density-based clustering identifying contiguous disease epicenters across farms.
    Each point dict should have: 'id', 'latitude', 'longitude', 'disease', 'farm_id', 'created_at'.
    """
    n = len(points)
    if n == 0:
        return []

    visited = [False] * n
    cluster_labels = [-1] * n
    current_cluster_id = 0

    # Build adjacency distance matrix
    for i in range(n):
        if visited[i]:
            continue
        visited[i] = True

        # Find neighbors within eps_km
        neighbors = []
        for j in range(n):
            if i == j:
                continue
            dist = haversine_distance(
                points[i]["latitude"],
                points[i]["longitude"],
                points[j]["latitude"],
                points[j]["longitude"],
            )
            if dist <= eps_km:
                neighbors.append(j)

        if len(neighbors) + 1 >= min_samples:
            cluster_labels[i] = current_cluster_id
            queue = list(neighbors)

            idx = 0
            while idx < len(queue):
                neighbor_idx = queue[idx]
                if not visited[neighbor_idx]:
                    visited[neighbor_idx] = True
                    # Find secondary neighbors
                    sec_neighbors = []
                    for k in range(n):
                        if neighbor_idx == k:
                            continue
                        dist = haversine_distance(
                            points[neighbor_idx]["latitude"],
                            points[neighbor_idx]["longitude"],
                            points[k]["latitude"],
                            points[k]["longitude"],
                        )
                        if dist <= eps_km:
                            sec_neighbors.append(k)

                    if len(sec_neighbors) + 1 >= min_samples:
                        for sn in sec_neighbors:
                            if sn not in queue:
                                queue.append(sn)

                if cluster_labels[neighbor_idx] == -1:
                    cluster_labels[neighbor_idx] = current_cluster_id
                idx += 1

            current_cluster_id += 1

    # Aggregate clusters
    clusters: List[Dict[str, Any]] = []
    for c_id in range(current_cluster_id):
        cluster_points = [points[i] for i in range(n) if cluster_labels[i] == c_id]
        if not cluster_points:
            continue

        center_lat = sum(p["latitude"] for p in cluster_points) / len(cluster_points)
        center_lon = sum(p["longitude"] for p in cluster_points) / len(cluster_points)

        # Count disease frequencies
        disease_counts: Dict[str, int] = {}
        farms_set = set()
        for p in cluster_points:
            d = p.get("disease", "Unknown")
            disease_counts[d] = disease_counts.get(d, 0) + 1
            if "farm_id" in p and p["farm_id"]:
                farms_set.add(p["farm_id"])

        primary_disease = max(disease_counts.items(), key=lambda x: x[1])[0]

        # Calculate max spread distance from center
        max_spread_km = max(
            haversine_distance(center_lat, center_lon, p["latitude"], p["longitude"])
            for p in cluster_points
        )
        containment_radius = max(5.0, round(max_spread_km + 2.0, 1))
        surveillance_radius = max(10.0, round(containment_radius * 2.0, 1))

        case_count = len(cluster_points)
        severity = (
            SeverityLevelEnum.CRITICAL
            if case_count >= 8 or primary_disease == "Anthrax"
            else SeverityLevelEnum.HIGH
            if case_count >= 4
            else SeverityLevelEnum.MEDIUM
        )

        clusters.append({
            "cluster_id": f"cluster-{c_id + 1}",
            "primary_disease": primary_disease,
            "case_count": case_count,
            "affected_farms_count": max(1, len(farms_set)),
            "epicenter_latitude": round(center_lat, 6),
            "epicenter_longitude": round(center_lon, 6),
            "containment_radius_km": containment_radius,
            "surveillance_radius_km": surveillance_radius,
            "severity": severity,
            "r0_estimate": calculate_r0(case_count, max(1, case_count // 2)),
            "disease_breakdown": disease_counts,
            "points": cluster_points,
        })

    return clusters


def generate_geojson_feature_collection(
    clusters: List[Dict[str, Any]],
    district_summaries: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Format clusters, quarantine rings, and district markers as standard RFC 7946 GeoJSON.
    """
    features: List[Dict[str, Any]] = []

    # 1. Cluster Epicenter Points & Buffer Polygons
    for cluster in clusters:
        c_id = cluster["cluster_id"]
        lat = cluster["epicenter_latitude"]
        lon = cluster["epicenter_longitude"]
        disease = cluster["primary_disease"]
        severity = cluster["severity"].value if hasattr(cluster["severity"], "value") else str(cluster["severity"])

        # Epicenter Point
        features.append({
            "type": "Feature",
            "id": f"{c_id}-epicenter",
            "geometry": {
                "type": "Point",
                "coordinates": [lon, lat],
            },
            "properties": {
                "feature_type": "epicenter",
                "cluster_id": c_id,
                "disease": disease,
                "case_count": cluster["case_count"],
                "affected_farms": cluster["affected_farms_count"],
                "severity": severity,
                "r0_estimate": cluster["r0_estimate"],
                "color": "#E53935" if severity in ["high", "critical"] else "#F59E0B",
            },
        })

        # 5km Containment Ring (Polygon)
        containment_coords = generate_circle_polygon(lat, lon, cluster["containment_radius_km"])
        features.append({
            "type": "Feature",
            "id": f"{c_id}-containment-zone",
            "geometry": {
                "type": "Polygon",
                "coordinates": [containment_coords],
            },
            "properties": {
                "feature_type": "containment_zone",
                "cluster_id": c_id,
                "zone_type": "containment",
                "radius_km": cluster["containment_radius_km"],
                "fill_color": "#EF4444",
                "fill_opacity": 0.25,
                "stroke_color": "#B91C1C",
                "stroke_width": 2,
                "label": f"5km Containment Zone ({disease})",
            },
        })

        # 10km Surveillance Buffer Ring (Polygon)
        surveillance_coords = generate_circle_polygon(lat, lon, cluster["surveillance_radius_km"])
        features.append({
            "type": "Feature",
            "id": f"{c_id}-surveillance-zone",
            "geometry": {
                "type": "Polygon",
                "coordinates": [surveillance_coords],
            },
            "properties": {
                "feature_type": "surveillance_zone",
                "cluster_id": c_id,
                "zone_type": "surveillance",
                "radius_km": cluster["surveillance_radius_km"],
                "fill_color": "#F59E0B",
                "fill_opacity": 0.12,
                "stroke_color": "#D97706",
                "stroke_width": 1.5,
                "label": f"10km Surveillance Buffer Zone ({disease})",
            },
        })

    # 2. District Risk Centroids (if provided)
    if district_summaries:
        for dist in district_summaries:
            severity = dist["severity"].value if hasattr(dist["severity"], "value") else str(dist["severity"])
            features.append({
                "type": "Feature",
                "id": f"district-{dist.get('district_id', dist['district_name'])}",
                "geometry": {
                    "type": "Point",
                    "coordinates": [dist["longitude"], dist["latitude"]],
                },
                "properties": {
                    "feature_type": "district_risk",
                    "district_name": dist["district_name"],
                    "district_name_mr": dist.get("district_name_mr", ""),
                    "risk_score": dist["risk_score"],
                    "severity": severity,
                    "active_cases": dist["active_cases"],
                    "r0_estimate": dist["r0_estimate"],
                },
            })

    return {
        "type": "FeatureCollection",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "total_clusters": len(clusters),
        "features": features,
    }
