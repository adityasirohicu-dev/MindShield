from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, get_current_user
from app.core.enums import ConsentDataType, ConsentStatus
from app.core.errors import APIError
from app.core.security import encrypt_text
from app.db.session import get_db
from app.modules.auth_consent.schemas import CheckInCreate, CheckInCreated, CheckInOut
from app.modules.auth_consent.service import upsert_consent
from app.modules.risk_engine.jobs import enqueue_scoring
from app.modules.wellness.mapping import normalize_checkin_scores
from app.modules.wellness.models import CheckIn

router = APIRouter(tags=["wellness"])

RANGE_DAYS = {"7d": 7, "14d": 14, "30d": 30, "90d": 90}


@router.post("/checkins", response_model=CheckInCreated)
def create_checkin(
    body: CheckInCreate,
    background: BackgroundTasks,
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckInCreated:
    if current.role.value != "personnel":
        raise APIError(403, "FORBIDDEN", "Only personnel can submit check-ins.")
    client_ts = body.client_submitted_at or datetime.now(UTC)
    if client_ts.tzinfo is None:
        client_ts = client_ts.replace(tzinfo=UTC)
    existing = db.scalars(
        select(CheckIn).where(
            CheckIn.user_id == current.id,
            CheckIn.client_submitted_at == client_ts,
        )
    ).first()
    if existing:
        return CheckInCreated(checkin_id=existing.checkin_id, submitted_at=existing.submitted_at)

    mood, stress, recovery = normalize_checkin_scores(
        mood_score=body.mood_score,
        stress_score=body.stress_score,
        recovery_score=body.recovery_score,
        readiness_state=body.readiness_state.value if body.readiness_state else None,
        duty_stress_10=body.duty_stress_10,
        sleep_hours=body.sleep_hours,
        rest_quality=body.rest_quality.value if body.rest_quality else None,
    )
    row = CheckIn(
        user_id=current.id,
        mood_score=mood,
        stress_score=stress,
        recovery_score=recovery,
        note_encrypted=encrypt_text(body.note),
        readiness_state=body.readiness_state.value if body.readiness_state else None,
        duty_stress_10=body.duty_stress_10,
        sleep_hours=body.sleep_hours,
        rest_quality=body.rest_quality.value if body.rest_quality else None,
        friction_factors=body.friction_factors,
        client_submitted_at=client_ts,
        submitted_at=client_ts,
    )
    db.add(row)
    if body.early_warning_consent is True:
        upsert_consent(db, current.user, ConsentDataType.RISK_SCORING, ConsentStatus.GRANTED)
    elif body.early_warning_consent is False:
        upsert_consent(db, current.user, ConsentDataType.RISK_SCORING, ConsentStatus.REVOKED)
    db.commit()
    db.refresh(row)
    enqueue_scoring(background, current.id)
    return CheckInCreated(checkin_id=row.checkin_id, submitted_at=row.submitted_at)


@router.get("/checkins/me", response_model=list[CheckInOut])
def my_checkins(
    range: str = Query(default="7d"),
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CheckInOut]:
    days = RANGE_DAYS.get(range)
    if days is None:
        raise APIError(422, "VALIDATION_ERROR", "range must be one of 7d, 14d, 30d, 90d.")
    since = datetime.now(UTC) - timedelta(days=days)
    rows = db.scalars(
        select(CheckIn)
        .where(CheckIn.user_id == current.id, CheckIn.submitted_at >= since)
        .order_by(CheckIn.submitted_at.asc())
    )
    return [
        CheckInOut(
            submitted_at=r.submitted_at,
            mood_score=r.mood_score,
            stress_score=r.stress_score,
            recovery_score=r.recovery_score,
            sleep_hours=r.sleep_hours,
            rest_quality=r.rest_quality,
            readiness_state=r.readiness_state,
            friction_factors=r.friction_factors,
        )
        for r in rows
    ]
