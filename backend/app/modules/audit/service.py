from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.audit.models import AuditLog


def write_audit(
    db: Session,
    *,
    actor_id: UUID,
    action: str,
    target_user_id: UUID | None = None,
    reason_code: str | None = None,
) -> AuditLog:
    entry = AuditLog(
        actor_id=actor_id,
        action=action,
        target_user_id=target_user_id,
        reason_code=reason_code,
    )
    db.add(entry)
    db.flush()
    return entry


def list_audit(
    db: Session,
    *,
    user_id: UUID | None,
    actor_id: UUID | None,
    from_ts: datetime | None,
    to_ts: datetime | None,
) -> list[AuditLog]:
    stmt = select(AuditLog).order_by(AuditLog.timestamp.desc())
    if user_id:
        stmt = stmt.where(AuditLog.target_user_id == user_id)
    if actor_id:
        stmt = stmt.where(AuditLog.actor_id == actor_id)
    if from_ts:
        stmt = stmt.where(AuditLog.timestamp >= from_ts)
    if to_ts:
        stmt = stmt.where(AuditLog.timestamp <= to_ts)
    return list(db.scalars(stmt.limit(500)))
