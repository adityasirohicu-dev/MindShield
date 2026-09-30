from enum import StrEnum


class UserRole(StrEnum):
    PERSONNEL = "personnel"
    WELFARE_OFFICER = "welfare_officer"
    COUNSELLOR = "counsellor"
    ORG_ADMIN = "org_admin"


class UserStatus(StrEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"


class ConsentDataType(StrEnum):
    ACCELEROMETER = "accelerometer"
    GYROSCOPE = "gyroscope"
    APP_USAGE = "app_usage"
    AMBIENT_LIGHT = "ambient_light"
    SPEECH_FEATURES = "speech_features"
    WEARABLE = "wearable"
    RISK_SCORING = "risk_scoring"


class ConsentStatus(StrEnum):
    GRANTED = "granted"
    REVOKED = "revoked"


class DeploymentStatus(StrEnum):
    GARRISON = "garrison"
    DEPLOYED = "deployed"
    LEAVE = "leave"
    TRAINING = "training"


class SensorFeatureType(StrEnum):
    ACTIVITY_LEVEL = "activity_level"
    APP_USAGE_PATTERN = "app_usage_pattern"
    AMBIENT_CONTEXT = "ambient_context"
    SPEECH_TONE_FEATURE = "speech_tone_feature"


SENSOR_CONSENT_MAP = {
    SensorFeatureType.ACTIVITY_LEVEL: ConsentDataType.ACCELEROMETER,
    SensorFeatureType.APP_USAGE_PATTERN: ConsentDataType.APP_USAGE,
    SensorFeatureType.AMBIENT_CONTEXT: ConsentDataType.AMBIENT_LIGHT,
    SensorFeatureType.SPEECH_TONE_FEATURE: ConsentDataType.SPEECH_FEATURES,
}


class RiskLevel(StrEnum):
    LOW = "low"
    MODERATE = "moderate"
    ELEVATED = "elevated"
    HIGH = "high"


class ReviewStatus(StrEnum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    ACTIONED = "actioned"


class CounsellingSource(StrEnum):
    SELF_REQUESTED = "self_requested"
    RISK_FLAGGED = "risk_flagged"


class CounsellingStatus(StrEnum):
    REQUESTED = "requested"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    CLOSED = "closed"


class ReadinessState(StrEnum):
    ENERGETIC_ALERT = "energetic_alert"
    STEADY_FOCUSED = "steady_focused"
    FATIGUED_STRAINED = "fatigued_strained"
    ANXIOUS_OVERWHELMED = "anxious_overwhelmed"
    EXHAUSTED = "exhausted"


class RestQuality(StrEnum):
    RESTFUL = "restful"
    INTERRUPTED = "interrupted"
    POOR = "poor"


class CounsellingChannel(StrEnum):
    ANONYMOUS_VOICE = "anonymous_voice"
    SECURE_CHAT = "secure_chat"
    BASE_CLINIC = "base_clinic"


class CounsellingUrgency(StrEnum):
    ROUTINE_48H = "routine_48h"
    PRIORITY_4H = "priority_4h"
