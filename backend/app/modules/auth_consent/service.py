from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.enums import ConsentDataType, ConsentStatus
from app.core.errors import APIError
from app.modules.audit.service import write_audit
from app.modules.auth_consent.models import ConsentRecord, User


def ensure_consent_rows(db: Session, user_id: UUID) -> None:
    existing = {c.data_type for c in db.scalars(select(ConsentRecord).where(ConsentRecord.user_id == user_id))}
    for data_type in ConsentDataType:
        if data_type.value not in existing:
            db.add(
                ConsentRecord(
                    user_id=user_id,
                    data_type=data_type.value,
                    status=ConsentStatus.REVOKED.value,
                )
            )
    db.flush()


def list_consent(db: Session, user_id: UUID) -> list[ConsentRecord]:
    ensure_consent_rows(db, user_id)
    return list(db.scalars(select(ConsentRecord).where(ConsentRecord.user_id == user_id)))


def upsert_consent(
    db: Session,
    user: User,
    data_type: ConsentDataType,
    status: ConsentStatus,
) -> ConsentRecord:
    ensure_consent_rows(db, user.user_id)
    record = db.scalars(
        select(ConsentRecord).where(
            ConsentRecord.user_id == user.user_id,
            ConsentRecord.data_type == data_type.value,
        )
    ).first()
    assert record is not None
    now = datetime.now(UTC)
    record.status = status.value
    if status == ConsentStatus.GRANTED:
        record.granted_at = now
        record.revoked_at = None
    else:
        record.revoked_at = now
    write_audit(
        db,
        actor_id=user.user_id,
        action="consent_updated",
        target_user_id=user.user_id,
        reason_code=f"{data_type.value}:{status.value}",
    )
    db.flush()
    return record


def require_granted(db: Session, user_id: UUID, data_type: ConsentDataType) -> None:
    record = db.scalars(
        select(ConsentRecord).where(
            ConsentRecord.user_id == user_id,
            ConsentRecord.data_type == data_type.value,
        )
    ).first()
    if record is None or record.status != ConsentStatus.GRANTED.value:
        raise APIError(
            403,
            "CONSENT_REQUIRED",
            "This action requires active consent for the requested data type.",
        )
