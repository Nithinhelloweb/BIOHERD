import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.models import Alert, Farm, SeverityLevelEnum, User, UserRole
from app.services.outbreak_detector import haversine_distance

logger = logging.getLogger("bioherd.notifications")


OUTBREAK_NOTIFICATION_TEMPLATES = {
    "Foot and Mouth Disease": {
        "title_en": "CRITICAL: Foot and Mouth Disease (FMD) Outbreak Declared",
        "title_mr": "तातडीची सूचना: लाळ्या खुरकूत (FMD) प्रादुर्भाव जाहीर",
        "body_en": (
            "An active FMD hotspot was confirmed within {radius_km}km of your farm in {district_name}. "
            "Immediately isolate cloven-hoofed animals, suspend livestock movement, and avoid shared water troughs."
        ),
        "body_mr": (
            "{district_name} परिसरात आपल्या गोठ्यापासून {radius_km} किमी परिघात लाळ्या खुरकूत रोगाचा प्रादुर्भाव आढळला आहे. "
            "जनावरांचे तातडीने विलगीकरण करा, जनावरांची वाहतूक थांबवा व सामूहिक चराई बंद करा."
        ),
        "severity": SeverityLevelEnum.CRITICAL,
    },
    "Lumpy Skin Disease": {
        "title_en": "WARNING: Lumpy Skin Disease (LSD) Hotspot Detected",
        "title_mr": "सतर्कता: गाठींचा त्वचा रोग (LSD) प्रादुर्भाव",
        "body_en": (
            "LSD cluster active within {radius_km}km of your farm in {district_name}. "
            "Spray anti-fly and tick repellents in the shed, isolate animals showing skin nodules, and report immediately."
        ),
        "body_mr": (
            "{district_name} जवळ आपल्या गोठ्यापासून {radius_km} किमी परिसरात गाठींचा त्वचा रोग आढळला आहे. "
            "गोठ्यात डास व गोचीड प्रतिबंधक फवारणी करा आणि अंगावर गाठी दिसल्यास तातडीने नोंदवा."
        ),
        "severity": SeverityLevelEnum.HIGH,
    },
    "Anthrax": {
        "title_en": "BIOHAZARD: Anthrax Alert - Strictly Do Not Open Carcasses",
        "title_mr": "धोकादायक सूचना: काळपुळी (अँथ्रॅक्स) अलर्ट - मृत जनावरे उघडू नका",
        "body_en": (
            "Severe Anthrax biohazard warning in {district_name} ({radius_km}km zone). "
            "Strictly DO NOT open or skin dead animal carcasses. Call 1962 Animal Helpline immediately."
        ),
        "body_mr": (
            "{district_name} मध्ये {radius_km} किमी क्षेत्रात काळपुळीचा तीव्र धोका. "
            "मृत जनावरांचे शवविच्छेदन किंवा कातडी काढणे सक्त मनाई आहे. त्वरित १९६२ हेल्पलाइनवर संपर्क साधा."
        ),
        "severity": SeverityLevelEnum.CRITICAL,
    },
    "Haemorrhagic Septicaemia": {
        "title_en": "HIGH ALERT: Haemorrhagic Septicaemia (Ghatsarpa) Outbreak",
        "title_mr": "दक्षता इशारा: घटसर्प (HS) आजाराचा उद्रेक",
        "body_en": (
            "HS transmission active in {district_name} within {radius_km}km. "
            "Monitor animals for hot throat/brisket swelling and labored breathing. Emergency vaccination drive active."
        ),
        "body_mr": (
            "{district_name} मध्ये {radius_km} किमी परिसरात घटसर्प आजाराची नोंद. "
            "घशाखाली सूज व धाप लागल्याचे आढळल्यास लगेच पशुवैद्यकीय दवाखान्यात धाव घ्या."
        ),
        "severity": SeverityLevelEnum.HIGH,
    },
    "Black Quarter": {
        "title_en": "ALERT: Black Quarter (Ek-tangya) Detected in District",
        "title_mr": "दक्षता सूचना: एकटांग्या (BQ) प्रादुर्भाव",
        "body_en": (
            "Black Quarter confirmed within {radius_km}km in {district_name}. "
            "Check young cattle for hot crepitating muscle swelling and sudden severe lameness."
        ),
        "body_mr": (
            "{district_name} मध्ये {radius_km} किमी परिघात एकटांग्या आजार आढळला आहे. "
            "जनावरांच्या पुठ्ठ्यावर सूज व तीव्र लंगडणे आढळल्यास तातडीने उपचार करा."
        ),
        "severity": SeverityLevelEnum.HIGH,
    },
}


class NotificationService:
    @staticmethod
    async def get_farmers_in_radius(
        session: AsyncSession,
        epicenter_lat: float,
        epicenter_lon: float,
        radius_km: float = 10.0,
    ) -> List[Dict[str, Any]]:
        """
        Find all farms and their owner user details within radius_km of the epicenter.
        """
        stmt = select(Farm).join(User, Farm.owner_user_id == User.id)
        res = await session.execute(stmt)
        all_farms = res.scalars().all()

        nearby_farmers = []
        seen_users = set()

        for farm in all_farms:
            dist = haversine_distance(epicenter_lat, epicenter_lon, farm.latitude, farm.longitude)
            if dist <= radius_km:
                if farm.owner_user_id not in seen_users:
                    seen_users.add(farm.owner_user_id)
                    nearby_farmers.append({
                        "user_id": farm.owner_user_id,
                        "farm_id": farm.id,
                        "farm_name": farm.name,
                        "distance_km": round(dist, 2),
                    })

        return nearby_farmers

    @staticmethod
    async def broadcast_outbreak_alert(
        session: AsyncSession,
        disease_name: str,
        district_name: str,
        epicenter_lat: float,
        epicenter_lon: float,
        radius_km: float = 10.0,
        custom_notes_en: Optional[str] = None,
        custom_notes_mr: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create in-app Alert records for all livestock owners and district vets within radius_km.
        """
        template = OUTBREAK_NOTIFICATION_TEMPLATES.get(
            disease_name,
            {
                "title_en": f"OUTBREAK ALERT: {disease_name} Reported",
                "title_mr": f"दक्षता सूचना: {disease_name} ची नोंद",
                "body_en": f"A confirmed {disease_name} cluster was detected within {radius_km}km in {district_name}. Isolate sick stock.",
                "body_mr": f"{district_name} मध्ये {radius_km} किमी परिसरात {disease_name} आढळला आहे. आजारी जनावरे वेगळी ठेवा.",
                "severity": SeverityLevelEnum.HIGH,
            },
        )

        title_en = template["title_en"]
        title_mr = template["title_mr"]
        body_en = template["body_en"].format(radius_km=radius_km, district_name=district_name)
        body_mr = template["body_mr"].format(radius_km=radius_km, district_name=district_name)

        if custom_notes_en:
            body_en += f" Directive: {custom_notes_en}"
        if custom_notes_mr:
            body_mr += f" विशेष सूचना: {custom_notes_mr}"

        # 1. Fetch nearby farmers
        farmers = await NotificationService.get_farmers_in_radius(
            session=session,
            epicenter_lat=epicenter_lat,
            epicenter_lon=epicenter_lon,
            radius_km=radius_km,
        )

        # 2. Fetch veterinarians & district officials in the same district or state
        stmt_officials = select(User).where(
            User.role.in_([UserRole.VETERINARIAN, UserRole.DISTRICT_OFFICIAL, UserRole.STATE_ADMIN])
        )
        res_officials = await session.execute(stmt_officials)
        officials = res_officials.scalars().all()

        recipient_user_ids = set(f["user_id"] for f in farmers)
        for off in officials:
            recipient_user_ids.add(off.id)

        created_alerts = []
        now = datetime.now(timezone.utc)

        for user_id in recipient_user_ids:
            alert = Alert(
                recipient_user_id=user_id,
                alert_type="outbreak",
                severity=template["severity"],
                title_multilingual_json={"en": title_en, "mr": title_mr},
                body_multilingual_json={"en": body_en, "mr": body_mr},
                channels=["push", "sms"],
                is_read=False,
                created_at=now,
            )
            session.add(alert)
            created_alerts.append(alert)

        await session.flush()

        logger.info(
            f"Dispatched outbreak alert for {disease_name} to {len(created_alerts)} recipients "
            f"within {radius_km}km of ({epicenter_lat}, {epicenter_lon})"
        )

        return {
            "disease_name": disease_name,
            "district_name": district_name,
            "radius_km": radius_km,
            "recipients_count": len(created_alerts),
            "nearby_farms_count": len(farmers),
            "alert_ids": [a.id for a in created_alerts],
            "severity": template["severity"].value,
            "channels": ["push", "sms"],
            "dispatched_at": now.isoformat(),
        }
