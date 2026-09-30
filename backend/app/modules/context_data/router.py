from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, require_roles
from app.core.enums import UserRole
from app.db.session import get_db
from app.modules.auth_consent.schemas import DutyContextCreate, DutyContextCreated
from app.modules.auth_consent.models import User
from app.modules.context_data.models import DutyContext
from app.modules.context_data.quality import validate_duty_payload
from app.modules.risk_engine.jobs import enqueue_scoring
from app.core.errors import APIError
from fastapi import BackgroundTasks

router = APIRouter(tags=["context"])


@router.post("/context/duty", response_model=DutyContextCreated)
def ingest_duty(
    body: DutyContextCreate,
    background: BackgroundTasks,
    current: CurrentUser = Depends(require_roles(UserRole.ORG_ADMIN)),
    db: Session = Depends(get_db),
) -> DutyContextCreated:
    validate_duty_payload(body)
    target = db.get(User, body.user_id)
    if target is None:
        raise APIError(404, "NOT_FOUND", "User not found.")
    row = DutyContext(
        user_id=body.user_id,
        leave_days_recent=body.leave_days_recent,
        deployment_status=body.deployment_status.value,
        duty_hours_weekly=body.duty_hours_weekly,
        transfer_count_recent=body.transfer_count_recent,
        training_load=body.training_load,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    enqueue_scoring(background, body.user_id)
    return DutyContextCreated(context_id=row.context_id)
