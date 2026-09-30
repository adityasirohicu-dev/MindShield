from datetime import UTC, datetime, timedelta
from statistics import mean
from uuid import UUID

from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.modules.auth_consent.models import User
from app.modules.context_data.models import DutyContext
from app.modules.sensor_ingestion.models import SensorFeature
from app.modules.wellness.models import CheckIn


WINDOW_DAYS = 14


def _window_start() -> datetime:
    return datetime.now(UTC) - timedelta(days=WINDOW_DAYS)


def aggregate_user_features(db: Session, user_id: UUID) -> dict:
    start = _window_start()
    checkins = list(
        db.scalars(
            select(CheckIn)
            .where(CheckIn.user_id == user_id, CheckIn.submitted_at >= start)
            .order_by(CheckIn.submitted_at.asc())
        )
    )
    duty = db.scalars(
        select(DutyContext)
        .where(DutyContext.user_id == user_id)
        .order_by(DutyContext.recorded_at.desc())
        .limit(1)
    ).first()
    user = db.get(User, user_id)
    sensors: list[SensorFeature] = []
    if user and not user.exclude_sensor_from_scoring:
        sensors = list(
            db.scalars(
                select(SensorFeature).where(
                    SensorFeature.user_id == user_id, SensorFeature.window_end >= start
                )
            )
        )

    avg_stress = mean([c.stress_score for c in checkins]) if checkins else 3.0
    avg_recovery = mean([c.recovery_score for c in checkins]) if checkins else 3.0
    if len(checkins) >= 4:
        mid = len(checkins) // 2
        first = mean([c.stress_score for c in checkins[:mid]])
        second = mean([c.stress_score for c in checkins[mid:]])
        stress_trend = second - first
    else:
        stress_trend = 0.0

    sleep_hours = [c.sleep_hours for c in checkins if c.sleep_hours is not None]
    sleep_deficit = max(0.0, 7.0 - mean(sleep_hours)) if sleep_hours else 0.0

    friction = set()
    traumatic = False
    for c in checkins:
        factors = c.friction_factors or []
        for f in factors:
            if f and f != "none_today":
                friction.add(str(f))
            if "traumatic" in str(f):
                traumatic = True

    last_checkin = checkins[-1].submitted_at if checkins else None
    if last_checkin is not None:
        if last_checkin.tzinfo is None:
            last_checkin = last_checkin.replace(tzinfo=UTC)
        gap = (datetime.now(UTC) - last_checkin).total_seconds() / 86400
    else:
        gap = float(WINDOW_DAYS)

    activity_load = 0.0
    for s in sensors:
        if s.feature_type == "activity_level" and isinstance(s.value, dict):
            activity_load = max(activity_load, float(s.value.get("load", s.value.get("value", 0)) or 0))

    return {
        "avg_stress": avg_stress,
        "stress_trend": stress_trend,
        "avg_recovery": avg_recovery,
        "sleep_deficit": sleep_deficit,
        "duty_hours_weekly": duty.duty_hours_weekly if duty else 40.0,
        "training_load": duty.training_load if duty else 0.0,
        "transfer_count_recent": duty.transfer_count_recent if duty else 0,
        "friction_count": len(friction),
        "traumatic_flag": traumatic,
        "checkin_gap_days": gap,
        "activity_load": activity_load,
        "checkin_count": len(checkins),
    }
