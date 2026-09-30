from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, require_roles
from app.core.enums import UserRole
from app.db.session import get_db
from app.modules.audit.service import list_audit
from app.modules.auth_consent.schemas import AuditLogOut

router = APIRouter(tags=["audit"])


@router.get("/audit/logs", response_model=list[AuditLogOut])
def get_logs(
    user_id: UUID | None = Query(default=None),
    actor_id: UUID | None = Query(default=None),
    from_ts: datetime | None = Query(default=None, alias="from"),
    to_ts: datetime | None = Query(default=None, alias="to"),
    current: CurrentUser = Depends(require_roles(UserRole.ORG_ADMIN)),
    db: Session = Depends(get_db),
) -> list[AuditLogOut]:
    rows = list_audit(db, user_id=user_id, actor_id=actor_id, from_ts=from_ts, to_ts=to_ts)
    return [
        AuditLogOut(
            actor_id=r.actor_id,
            action=r.action,
            target_user_id=r.target_user_id,
            timestamp=r.timestamp,
            reason_code=r.reason_code,
        )
        for r in rows
    ]
