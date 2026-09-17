import enum
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    JSON,
    String,
    Table,
    Text,
    Enum as SQLEnum,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

# Enumerations matching SYSTEM_PROMPT.md
class UserRole(str, enum.Enum):
    FARMER = "farmer"
    VETERINARIAN = "veterinarian"
    DISTRICT_OFFICIAL = "district_official"
    STATE_ADMIN = "state_admin"
    SUPER_ADMIN = "super_admin"

class AnimalSpecies(str, enum.Enum):
    CATTLE = "cattle"
    BUFFALO = "buffalo"
    GOAT = "goat"
    SHEEP = "sheep"
    PIG = "pig"
    POULTRY = "poultry"

class SeverityLevelEnum(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class CaseStatusEnum(str, enum.Enum):
    SUBMITTED = "submitted"
    ASSIGNED = "assigned"
    IN_REVIEW = "in_review"
    PRESCRIPTION_ISSUED = "prescription_issued"
    FOLLOW_UP = "follow_up"
    CLOSED = "closed"

class HealthEventType(str, enum.Enum):
    VACCINATION = "vaccination"
    DISEASE = "disease"
    MEDICATION = "medication"
    ROUTINE_CHECKUP = "routine_checkup"
    QUARANTINE = "quarantine"

# 1. Users Table
class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    phone: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), unique=True, index=True, nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    full_name: Mapped[str] = mapped_column(String(120), default="")
    role: Mapped[UserRole] = mapped_column(SQLEnum(UserRole), default=UserRole.FARMER, index=True)
    preferred_language: Mapped[str] = mapped_column(String(10), default="mr") # mr, hi, en
    district_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("districts.id"), nullable=True)
    is_2fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    totp_secret: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    farms = relationship("Farm", back_populates="owner", cascade="all, delete-orphan")
    alerts = relationship("Alert", back_populates="recipient", cascade="all, delete-orphan")

# 2. Districts Table (36 Maharashtra Districts)
class District(Base):
    __tablename__ = "districts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    name: Mapped[str] = mapped_column(String(100), unique=True, index=True) # e.g. Pune, Nashik
    name_mr: Mapped[str] = mapped_column(String(100), default="")           # e.g. पुणे, नाशिक
    state: Mapped[str] = mapped_column(String(50), default="Maharashtra")
    latitude: Mapped[float] = mapped_column(Float, default=18.5204)
    longitude: Mapped[float] = mapped_column(Float, default=73.8567)
    livestock_population: Mapped[int] = mapped_column(Integer, default=0)
    boundary_geojson: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    farms = relationship("Farm", back_populates="district")
    drug_inventory = relationship("DrugInventory", back_populates="district")
    outbreak_events = relationship("OutbreakEvent", back_populates="district")

# 3. Farms Table
class Farm(Base):
    __tablename__ = "farms"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    owner_user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(150))
    district_id: Mapped[str] = mapped_column(String(36), ForeignKey("districts.id"), index=True)
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    address: Mapped[str] = mapped_column(String(255), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    owner = relationship("User", back_populates="farms")
    district = relationship("District", back_populates="farms")
    animals = relationship("Animal", back_populates="farm", cascade="all, delete-orphan")

# 4. Animals Table
class Animal(Base):
    __tablename__ = "animals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    farm_id: Mapped[str] = mapped_column(String(36), ForeignKey("farms.id"), index=True)
    species: Mapped[AnimalSpecies] = mapped_column(SQLEnum(AnimalSpecies), index=True)
    breed: Mapped[str] = mapped_column(String(100), index=True)
    sex: Mapped[str] = mapped_column(String(10)) # male, female
    dob: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    weight_kg: Mapped[float] = mapped_column(Float, default=0.0)
    tag_id: Mapped[str] = mapped_column(String(50), unique=True, index=True) # Unique B-Tree Index
    qr_code_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    farm = relationship("Farm", back_populates="animals")
    health_events = relationship("HealthEvent", back_populates="animal", cascade="all, delete-orphan")
    symptom_reports = relationship("SymptomReport", back_populates="animal", cascade="all, delete-orphan")
    vaccinations = relationship("Vaccination", back_populates="animal", cascade="all, delete-orphan")
    sensor_readings = relationship("SensorReading", back_populates="animal", cascade="all, delete-orphan")

# 5. Health Events Table (Composite index: animal_id + occurred_at)
class HealthEvent(Base):
    __tablename__ = "health_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    animal_id: Mapped[str] = mapped_column(String(36), ForeignKey("animals.id"), index=True)
    event_type: Mapped[HealthEventType] = mapped_column(SQLEnum(HealthEventType), index=True)
    description: Mapped[str] = mapped_column(Text)
    recorded_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    animal = relationship("Animal", back_populates="health_events")

    __table_args__ = (
        Index("ix_health_events_animal_occurred", "animal_id", "occurred_at"),
    )

# 6. Symptom Reports Table (Composite index: status + created_at)
class SymptomReport(Base):
    __tablename__ = "symptom_reports"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    animal_id: Mapped[str] = mapped_column(String(36), ForeignKey("animals.id"), index=True)
    reported_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    symptoms_json: Mapped[Dict[str, Any]] = mapped_column(JSON, default=dict)
    severity: Mapped[SeverityLevelEnum] = mapped_column(SQLEnum(SeverityLevelEnum), default=SeverityLevelEnum.LOW)
    status: Mapped[str] = mapped_column(String(50), default="submitted", index=True)
    voice_note_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    images_json: Mapped[List[str]] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    animal = relationship("Animal", back_populates="symptom_reports")
    detection_results = relationship("DetectionResult", back_populates="symptom_report", cascade="all, delete-orphan")
    case = relationship("Case", back_populates="symptom_report", uselist=False)

    __table_args__ = (
        Index("ix_symptom_reports_status_created", "status", "created_at"),
    )

# 7. Detection Results Table
class DetectionResult(Base):
    __tablename__ = "detection_results"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    symptom_report_id: Mapped[str] = mapped_column(String(36), ForeignKey("symptom_reports.id"), index=True)
    model_version: Mapped[str] = mapped_column(String(100), default="ensemble-v1.0")
    predictions_json: Mapped[List[Dict[str, Any]]] = mapped_column(JSON, default=list)
    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    inference_duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    symptom_report = relationship("SymptomReport", back_populates="detection_results")

# 8. Cases Table
class Case(Base):
    __tablename__ = "cases"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    symptom_report_id: Mapped[str] = mapped_column(String(36), ForeignKey("symptom_reports.id"), unique=True)
    assigned_vet_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id"), nullable=True, index=True)
    status: Mapped[CaseStatusEnum] = mapped_column(SQLEnum(CaseStatusEnum), default=CaseStatusEnum.SUBMITTED, index=True)
    priority: Mapped[SeverityLevelEnum] = mapped_column(SQLEnum(SeverityLevelEnum), default=SeverityLevelEnum.MEDIUM, index=True)
    telemedicine_session_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    resolution_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    symptom_report = relationship("SymptomReport", back_populates="case", lazy="selectin")
    prescriptions = relationship("Prescription", back_populates="case", cascade="all, delete-orphan", lazy="selectin")

# 9. Prescriptions Table
class Prescription(Base):
    __tablename__ = "prescriptions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    case_id: Mapped[str] = mapped_column(String(36), ForeignKey("cases.id"), index=True)
    issued_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    drug_name: Mapped[str] = mapped_column(String(150))
    dosage: Mapped[str] = mapped_column(String(100))
    duration_days: Mapped[int] = mapped_column(Integer, default=5)
    instructions_multilingual_json: Mapped[Dict[str, str]] = mapped_column(JSON, default=dict)
    schedule_h_warning: Mapped[bool] = mapped_column(Boolean, default=False)
    milk_withdrawal_days: Mapped[int] = mapped_column(Integer, default=0)
    meat_withdrawal_days: Mapped[int] = mapped_column(Integer, default=0)
    digital_signature_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    pdf_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    case = relationship("Case", back_populates="prescriptions")

# 10. Vaccinations Table
class Vaccination(Base):
    __tablename__ = "vaccinations"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    animal_id: Mapped[str] = mapped_column(String(36), ForeignKey("animals.id"), index=True)
    vaccine_name: Mapped[str] = mapped_column(String(150), index=True) # FMD, BQ, HS, Anthrax
    batch_number: Mapped[str] = mapped_column(String(50))
    administered_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    administered_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    next_due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    certificate_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    animal = relationship("Animal", back_populates="vaccinations")

# 11. Drug Inventory Table (per District Veterinary Centre)
class DrugInventory(Base):
    __tablename__ = "drug_inventory"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    district_id: Mapped[str] = mapped_column(String(36), ForeignKey("districts.id"), index=True)
    drug_name: Mapped[str] = mapped_column(String(150), index=True)
    quantity: Mapped[float] = mapped_column(Float, default=0.0)
    unit: Mapped[str] = mapped_column(String(30), default="vials")
    expiry_date: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    district = relationship("District", back_populates="drug_inventory")

# 12. Sensor Readings Table (TimescaleDB Hypertable candidate)
class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    animal_id: Mapped[str] = mapped_column(String(36), ForeignKey("animals.id"), index=True)
    reading_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, index=True)
    temperature_c: Mapped[float] = mapped_column(Float)
    heart_rate_bpm: Mapped[int] = mapped_column(Integer)
    activity_index: Mapped[float] = mapped_column(Float, default=1.0)
    rumination_minutes: Mapped[float] = mapped_column(Float, default=0.0)

    animal = relationship("Animal", back_populates="sensor_readings")

    __table_args__ = (
        Index("ix_sensor_animal_reading", "animal_id", "reading_time"),
    )

# 13. Alerts Table
class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    recipient_user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    alert_type: Mapped[str] = mapped_column(String(50)) # outbreak, diagnosis, vaccination_due, anomaly
    severity: Mapped[SeverityLevelEnum] = mapped_column(SQLEnum(SeverityLevelEnum), default=SeverityLevelEnum.MEDIUM)
    title_multilingual_json: Mapped[Dict[str, str]] = mapped_column(JSON, default=dict)
    body_multilingual_json: Mapped[Dict[str, str]] = mapped_column(JSON, default=dict)
    channels: Mapped[List[str]] = mapped_column(JSON, default=lambda: ["push"]) # push, sms, email
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    recipient = relationship("User", back_populates="alerts")

# 14. Audit Log Table (Immutable ledger)
class AuditLog(Base):
    __tablename__ = "audit_log"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    actor_user_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(50)) # CREATE, UPDATE, DELETE
    entity_type: Mapped[str] = mapped_column(String(50), index=True) # Animal, Case, Prescription
    entity_id: Mapped[str] = mapped_column(String(36), index=True)
    diff_json: Mapped[Dict[str, Any]] = mapped_column(JSON, default=dict)
    ip_address: Mapped[str] = mapped_column(String(45), default="127.0.0.1")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, index=True)

# 15. Outbreak Events Table
class OutbreakEvent(Base):
    __tablename__ = "outbreak_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    district_id: Mapped[str] = mapped_column(String(36), ForeignKey("districts.id"), index=True)
    disease_name: Mapped[str] = mapped_column(String(150), index=True)
    case_count: Mapped[int] = mapped_column(Integer, default=1)
    risk_level: Mapped[SeverityLevelEnum] = mapped_column(SQLEnum(SeverityLevelEnum), default=SeverityLevelEnum.HIGH)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    containment_radius_km: Mapped[float] = mapped_column(Float, default=5.0)
    surveillance_radius_km: Mapped[float] = mapped_column(Float, default=10.0)
    r0_estimate: Mapped[float] = mapped_column(Float, default=1.5)
    transmission_rate: Mapped[float] = mapped_column(Float, default=0.25)
    affected_farms_count: Mapped[int] = mapped_column(Integer, default=1)
    quarantine_declared: Mapped[bool] = mapped_column(Boolean, default=False)
    notes_multilingual_json: Mapped[Dict[str, str]] = mapped_column(JSON, default=dict)
    declared_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    district = relationship("District", back_populates="outbreak_events")

# 16. Security Events Table
class SecurityEvent(Base):
    __tablename__ = "security_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    event_type: Mapped[str] = mapped_column(String(100), index=True) # FAILED_LOGIN, INVALID_TOKEN, RATE_LIMIT_EXCEEDED
    details_json: Mapped[Dict[str, Any]] = mapped_column(JSON, default=dict)
    ip_address: Mapped[str] = mapped_column(String(45), default="127.0.0.1")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, index=True)
