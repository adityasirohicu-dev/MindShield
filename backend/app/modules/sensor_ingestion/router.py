from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, get_current_user
from app.core.enums import SENSOR_CONSENT_MAP
from app.core.errors import APIError
from app.db.session import get_db
from app.modules.auth_consent.schemas import SensorFeatureCreate, SensorFeatureCreated
from app.modules.auth_consent.service import require_granted
from app.modules.risk_engine.jobs import enqueue_scoring
from app.modules.sensor_ingestion.models import SensorFeature

router = APIRouter(tags=["sensors"])

FORBIDDEN_KEYS = {"raw_stream", "samples", "audio", "waveform", "gps", "lat", "lon"}


@router.post("/sensors/features", response_model=SensorFeatureCreated)
def ingest_features(
    body: SensorFeatureCreate,
    background: BackgroundTasks,
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SensorFeatureCreated:
    if any(k in {x.lower() for x in body.value.keys()} for k in FORBIDDEN_KEYS):
        raise APIError(422, "VALIDATION_ERROR", "Raw stream payloads are not accepted.")
    consent_type = SENSOR_CONSENT_MAP[body.feature_type]
    require_granted(db, current.id, consent_type)
    row = SensorFeature(
        user_id=current.id,
        feature_type=body.feature_type.value,
        value=body.value,
        window_start=body.window_start,
        window_end=body.window_end,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    enqueue_scoring(background, current.id)
    return SensorFeatureCreated(feature_id=row.feature_id, accepted=True)
