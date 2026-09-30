"""Apply TTL retention for check-ins, sensor features, and (optionally) old assessments."""

from __future__ import annotations

import os
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
os.chdir(BACKEND_ROOT)

from sqlalchemy import delete  # noqa: E402

from app.core.config import get_settings  # noqa: E402
from app.db.session import SessionLocal  # noqa: E402
from app.modules.sensor_ingestion.models import SensorFeature  # noqa: E402
from app.modules.audit.models import AuditLog  # noqa: E402
from app.modules.wellness.models import CheckIn  # noqa: E402


def apply_retention() -> None:
    settings = get_settings()
    now = datetime.now(UTC)
    db = SessionLocal()
    try:
        c = db.execute(
            delete(CheckIn).where(
                CheckIn.submitted_at < now - timedelta(days=settings.retention_days_checkin)
            )
        )
        s = db.execute(
            delete(SensorFeature).where(
                SensorFeature.created_at < now - timedelta(days=settings.retention_days_sensor)
            )
        )
        a = db.execute(
            delete(AuditLog).where(
                AuditLog.timestamp < now - timedelta(days=settings.retention_days_audit)
            )
        )
        db.commit()
        print(f"Deleted check-ins={c.rowcount} sensor_features={s.rowcount} audit_logs={a.rowcount}")
    finally:
        db.close()


if __name__ == "__main__":
    apply_retention()
