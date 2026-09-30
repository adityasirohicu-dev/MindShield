from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.deps import CurrentUser, get_current_user, require_roles
from app.core.enums import ConsentDataType, ConsentStatus, RiskLevel, SENSOR_CONSENT_MAP, UserRole
from app.db.session import get_db
from app.modules.audit.service import write_audit
from app.modules.auth_consent.models import ConsentRecord, User
from app.modules.auth_consent.schemas import OrgTrendBucket, OrgTrendsOut, PrivacySourceOut, PurgeRequest, PurgeResult
from app.modules.auth_consent.service import list_consent
from app.modules.risk_engine.models import RiskAssessment
from app.modules.sensor_ingestion.models import SensorFeature
from app.modules.wellness.models import CheckIn

privacy_router = APIRouter(tags=["privacy"])
org_router = APIRouter(tags=["org"])

PURPOSES = {
    ConsentDataType.ACCELEROMETER.value: "Derived activity-level features for optional risk fusion.",
    ConsentDataType.GYROSCOPE.value: "Derived motion stability features; never raw IMU streams.",
    ConsentDataType.APP_USAGE.value: "Coarse app-usage pattern features processed on-device.",
    ConsentDataType.AMBIENT_LIGHT.value: "Ambient context windows, not camera or location.",
    ConsentDataType.SPEECH_FEATURES.value: "On-device speech features only — no raw audio stored.",
    ConsentDataType.WEARABLE.value: "Optional wearable-derived recovery metrics (future).",
    ConsentDataType.RISK_SCORING.value: "Early-warning scoring using check-ins and consented signals.",
}


@privacy_router.get("/privacy/sources", response_model=list[PrivacySourceOut])
def privacy_sources(
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[PrivacySourceOut]:
    consents = list_consent(db, current.id)
    db.commit()
    last_sensor = db.scalars(
        select(func.max(SensorFeature.created_at)).where(SensorFeature.user_id == current.id)
    ).first()
    last_checkin = db.scalars(
        select(func.max(CheckIn.submitted_at)).where(CheckIn.user_id == current.id)
    ).first()
    out = []
    for c in consents:
        last = last_sensor if c.data_type != ConsentDataType.RISK_SCORING.value else last_checkin
        out.append(
            PrivacySourceOut(
                data_type=c.data_type,
                status=ConsentStatus(c.status),
                purpose=PURPOSES.get(c.data_type, "Operational welfare support."),
                last_collected_at=last,
            )
        )
    return out


@privacy_router.post("/privacy/purge", response_model=PurgeResult)
def privacy_purge(
    body: PurgeRequest,
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PurgeResult:
    types = body.data_types or [
        ConsentDataType.ACCELEROMETER,
        ConsentDataType.GYROSCOPE,
        ConsentDataType.APP_USAGE,
        ConsentDataType.AMBIENT_LIGHT,
        ConsentDataType.SPEECH_FEATURES,
        ConsentDataType.WEARABLE,
    ]
    feature_types = [
        ft.value
        for ft, consent in SENSOR_CONSENT_MAP.items()
        if consent in types
    ]
    stmt = delete(SensorFeature).where(SensorFeature.user_id == current.id)
    if feature_types:
        stmt = stmt.where(SensorFeature.feature_type.in_(feature_types))
    result = db.execute(stmt)
    current.user.exclude_sensor_from_scoring = True
    write_audit(
        db,
        actor_id=current.id,
        action="purged_derived_features",
        target_user_id=current.id,
    )
    db.commit()
    return PurgeResult(
        deleted_sensor_features=result.rowcount or 0,
        excluded_from_future_scoring=True,
    )


@privacy_router.delete("/privacy/me")
def deletion_on_request(
    current: CurrentUser = Depends(require_roles(UserRole.PERSONNEL)),
    db: Session = Depends(get_db),
) -> dict:
    """DPDP-style deletion of wellness and derived sensor data (audit retained)."""
    db.execute(delete(SensorFeature).where(SensorFeature.user_id == current.id))
    db.execute(delete(CheckIn).where(CheckIn.user_id == current.id))
    write_audit(db, actor_id=current.id, action="deletion_on_request", target_user_id=current.id)
    db.commit()
    return {"status": "deleted_wellness_and_sensor_features"}


@org_router.get("/org/trends", response_model=OrgTrendsOut)
def org_trends(
    current: CurrentUser = Depends(require_roles(UserRole.ORG_ADMIN, UserRole.WELFARE_OFFICER, UserRole.COUNSELLOR)),
    db: Session = Depends(get_db),
) -> OrgTrendsOut:
    settings = get_settings()
    personnel_query = select(User).where(User.role == UserRole.PERSONNEL.value)
    if current.role != UserRole.ORG_ADMIN:
        personnel_query = personnel_query.where(User.unit_id == current.unit_id)
    personnel = list(db.scalars(personnel_query))
    latest: dict = {}
    for p in personnel:
        row = db.scalars(
            select(RiskAssessment)
            .where(RiskAssessment.user_id == p.user_id)
            .order_by(RiskAssessment.generated_at.desc())
            .limit(1)
        ).first()
        if row:
            latest[p.user_id] = row
    counts: dict[str, int] = {lvl.value: 0 for lvl in RiskLevel}
    wellness = []
    for row in latest.values():
        counts[row.risk_level] = counts.get(row.risk_level, 0) + 1
        wellness.append(row.wellness_index)
    suppressed = False
    buckets = []
    for lvl, count in counts.items():
        if 0 < count < settings.k_anonymity_min:
            suppressed = True
            continue
        buckets.append(OrgTrendBucket(risk_level=RiskLevel(lvl), count=count))
    units = db.scalar(select(func.count()).select_from(User).where(User.role == UserRole.ORG_ADMIN.value))
    from app.modules.auth_consent.models import Unit

    unit_count = db.scalar(select(func.count()).select_from(Unit)) or 0
    avg = round(sum(wellness) / len(wellness), 1) if wellness else None
    return OrgTrendsOut(
        unit_count=unit_count,
        personnel_count=len(personnel),
        suppressed_small_cells=suppressed,
        buckets=buckets,
        avg_wellness_index=avg,
    )
