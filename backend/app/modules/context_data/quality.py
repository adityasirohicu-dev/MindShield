from app.core.errors import APIError
from app.core.enums import DeploymentStatus
from app.modules.auth_consent.schemas import DutyContextCreate


def validate_duty_payload(body: DutyContextCreate) -> None:
    if body.duty_hours_weekly < 0 or body.duty_hours_weekly > 112:
        raise APIError(422, "DATA_QUALITY", "duty_hours_weekly out of acceptable range.")
    if body.leave_days_recent < 0 or body.leave_days_recent > 90:
        raise APIError(422, "DATA_QUALITY", "leave_days_recent out of acceptable range.")
    if body.training_load < 0 or body.training_load > 10:
        raise APIError(422, "DATA_QUALITY", "training_load out of acceptable range.")
    DeploymentStatus(body.deployment_status)
