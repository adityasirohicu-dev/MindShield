from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.enums import (
    ConsentDataType,
    ConsentStatus,
    CounsellingChannel,
    CounsellingSource,
    CounsellingStatus,
    CounsellingUrgency,
    DeploymentStatus,
    ReadinessState,
    RestQuality,
    ReviewStatus,
    RiskLevel,
    SensorFeatureType,
    UserRole,
)


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class LoginRequest(StrictModel):
    credential: str
    otp: str = Field(..., pattern=r"^\d{6}$")


class OtpRequest(StrictModel):
    credential: str = Field(..., min_length=3, max_length=254)
    email: str | None = Field(default=None, min_length=5, max_length=254)
    purpose: str = Field(default="login", pattern="^(login|register)$")


class OtpResponse(StrictModel):
    sent: bool
    delivery: str
    expires_in: int
    demo_otp: str | None = None


class LoginResponse(StrictModel):
    access_token: str
    refresh_token: str
    role: UserRole
    expires_in: int


class RegisterRequest(StrictModel):
    credential: str = Field(..., min_length=3, max_length=120)
    display_name: str = Field(..., min_length=1, max_length=120)
    email: str = Field(..., min_length=5, max_length=254)
    otp: str = Field(..., pattern=r"^\d{6}$")
    role: UserRole = UserRole.PERSONNEL
    unit_name: str = Field(default="Alpha Unit", max_length=120)
    rank_label: str = Field(default="Operator", max_length=80)

    @field_validator("email")
    @classmethod
    def validate_email(cls, email: str) -> str:
        if "@" not in email or "." not in email.rsplit("@", 1)[-1]:
            raise ValueError("A valid email address is required.")
        return email.strip().casefold()


class RegisterResponse(StrictModel):
    user_id: str
    role: UserRole
    access_token: str
    refresh_token: str
    expires_in: int


class RefreshRequest(StrictModel):
    refresh_token: str


class TokenResponse(StrictModel):
    access_token: str


class ConsentItem(StrictModel):
    data_type: str
    status: ConsentStatus
    granted_at: datetime | None = None
    consent_id: UUID | None = None


class ConsentUpdate(StrictModel):
    data_type: ConsentDataType
    status: ConsentStatus


class CheckInCreate(StrictModel):
    mood_score: int | None = Field(default=None, ge=1, le=5)
    stress_score: int | None = Field(default=None, ge=1, le=5)
    recovery_score: int | None = Field(default=None, ge=1, le=5)
    note: str | None = None
    readiness_state: ReadinessState | None = None
    duty_stress_10: int | None = Field(default=None, ge=1, le=10)
    sleep_hours: float | None = Field(default=None, ge=0, le=16)
    rest_quality: RestQuality | None = None
    friction_factors: list[str] | None = None
    client_submitted_at: datetime | None = None
    early_warning_consent: bool | None = None


class CheckInCreated(StrictModel):
    checkin_id: UUID
    submitted_at: datetime


class CheckInOut(StrictModel):
    submitted_at: datetime
    mood_score: int
    stress_score: int
    recovery_score: int
    sleep_hours: float | None = None
    rest_quality: str | None = None
    readiness_state: str | None = None
    friction_factors: list[str] | None = None


class DutyContextCreate(StrictModel):
    user_id: UUID
    leave_days_recent: int = 0
    deployment_status: DeploymentStatus
    duty_hours_weekly: float
    transfer_count_recent: int = 0
    training_load: float = 0


class DutyContextCreated(StrictModel):
    context_id: UUID


class SensorFeatureCreate(StrictModel):
    feature_type: SensorFeatureType
    value: dict
    window_start: datetime
    window_end: datetime


class SensorFeatureCreated(StrictModel):
    feature_id: UUID
    accepted: bool


class FactorOut(StrictModel):
    factor: str
    weight: float
    trend: str
    explanation: str | None = None


class RiskMeOut(StrictModel):
    risk_level: RiskLevel
    wellness_index: int
    generated_at: datetime
    forecast_text: str | None = None
    contributing_factors: list[FactorOut] = []
    status_chip: str | None = None


class RiskQueueItem(StrictModel):
    assessment_id: UUID
    user_ref: str
    risk_level: RiskLevel
    generated_at: datetime
    review_status: ReviewStatus


class RiskDetailOut(StrictModel):
    assessment_id: UUID
    risk_level: RiskLevel
    score: float
    contributing_factors: list[FactorOut]
    recommended_actions: list[str]
    generated_at: datetime
    review_status: ReviewStatus
    user_ref: str


class RiskReviewIn(StrictModel):
    action_taken: str
    notes: str | None = None
    feedback: str | None = None


class RiskReviewOut(StrictModel):
    review_status: ReviewStatus


class CounsellingCreate(StrictModel):
    source: CounsellingSource = CounsellingSource.SELF_REQUESTED
    preferred_contact: str | None = None
    note: str | None = None
    channel: CounsellingChannel | None = None
    time_window: str | None = None
    urgency: CounsellingUrgency | None = None


class CounsellingCreated(StrictModel):
    request_id: UUID
    status: CounsellingStatus


class CounsellingMine(StrictModel):
    request_id: UUID
    status: CounsellingStatus
    created_at: datetime
    source: CounsellingSource
    urgency: CounsellingUrgency | None = None


class CounsellingQueueItem(StrictModel):
    request_id: UUID
    source: CounsellingSource
    status: CounsellingStatus
    created_at: datetime
    urgency: CounsellingUrgency | None = None
    channel: CounsellingChannel | None = None
    preferred_contact: str | None = None
    time_window: str | None = None


class CounsellingPatch(StrictModel):
    status: CounsellingStatus
    notes: str | None = None


class CounsellingPatched(StrictModel):
    request_id: UUID
    status: CounsellingStatus


class AuditLogOut(StrictModel):
    actor_id: UUID
    action: str
    target_user_id: UUID | None
    timestamp: datetime
    reason_code: str | None = None


class PrivacySourceOut(StrictModel):
    data_type: str
    status: ConsentStatus
    purpose: str
    last_collected_at: datetime | None = None


class PurgeRequest(StrictModel):
    data_types: list[ConsentDataType] | None = None


class PurgeResult(StrictModel):
    deleted_sensor_features: int
    excluded_from_future_scoring: bool


class OrgTrendBucket(StrictModel):
    risk_level: RiskLevel
    count: int


class OrgTrendsOut(StrictModel):
    unit_count: int
    personnel_count: int
    suppressed_small_cells: bool
    buckets: list[OrgTrendBucket]
    avg_wellness_index: float | None = None
