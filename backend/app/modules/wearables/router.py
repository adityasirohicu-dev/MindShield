from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, require_roles
from app.core.enums import ConsentDataType, SensorFeatureType, UserRole
from app.core.errors import APIError
from app.db.session import get_db
from app.modules.auth_consent.service import require_granted
from app.modules.risk_engine.jobs import enqueue_scoring
from app.modules.sensor_ingestion.models import SensorFeature

router = APIRouter(tags=["wearables"])


class WearableFeatureIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    feature_type: str = Field(description="Derived wearable metric only, e.g. hrv_window")
    value: dict
    window_start: datetime
    window_end: datetime


class WearableFeatureOut(BaseModel):
    model_config = ConfigDict(extra="forbid")
    feature_id: str
    accepted: bool


@router.post("/wearables/features", response_model=WearableFeatureOut)
def ingest_wearable(
    body: WearableFeatureIn,
    background: BackgroundTasks,
    current: CurrentUser = Depends(require_roles(UserRole.PERSONNEL)),
    db: Session = Depends(get_db),
) -> WearableFeatureOut:
    if any(k in body.value for k in ("raw_ppg", "raw_ecg", "gps")):
        raise APIError(422, "VALIDATION_ERROR", "Raw wearable streams are not accepted.")
    require_granted(db, current.id, ConsentDataType.WEARABLE)
    row = SensorFeature(
        user_id=current.id,
        feature_type=SensorFeatureType.ACTIVITY_LEVEL.value,
        value={"source": "wearable", "metric": body.feature_type, **body.value},
        window_start=body.window_start,
        window_end=body.window_end,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    enqueue_scoring(background, current.id)
    return WearableFeatureOut(feature_id=str(row.feature_id), accepted=True)
