from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, optional_reason, require_roles
from app.core.enums import CounsellingStatus, UserRole
from app.core.errors import APIError
from app.core.security import encrypt_text
from app.db.session import get_db
from app.modules.audit.service import write_audit
from app.modules.auth_consent.models import User
from app.modules.auth_consent.schemas import (
    CounsellingCreate,
    CounsellingCreated,
    CounsellingMine,
    CounsellingPatch,
    CounsellingPatched,
    CounsellingQueueItem,
)
from app.modules.counselling.models import CounsellingRequest

router = APIRouter(tags=["counselling"])

TRANSITIONS = {
    CounsellingStatus.REQUESTED: {CounsellingStatus.ASSIGNED, CounsellingStatus.CLOSED},
    CounsellingStatus.ASSIGNED: {CounsellingStatus.IN_PROGRESS, CounsellingStatus.CLOSED},
    CounsellingStatus.IN_PROGRESS: {CounsellingStatus.CLOSED},
    CounsellingStatus.CLOSED: set(),
}


@router.post("/counselling/requests", response_model=CounsellingCreated)
def create_request(
    body: CounsellingCreate,
    current: CurrentUser = Depends(require_roles(UserRole.PERSONNEL)),
    db: Session = Depends(get_db),
) -> CounsellingCreated:
    row = CounsellingRequest(
        user_id=current.id,
        source=body.source.value,
        preferred_contact=body.preferred_contact,
        note_encrypted=encrypt_text(body.note),
        channel=body.channel.value if body.channel else None,
        time_window=body.time_window,
        urgency=body.urgency.value if body.urgency else None,
        status=CounsellingStatus.REQUESTED.value,
    )
    db.add(row)
    write_audit(db, actor_id=current.id, action="counselling_requested", target_user_id=current.id)
    db.commit()
    db.refresh(row)
    return CounsellingCreated(request_id=row.request_id, status=CounsellingStatus(row.status))


@router.get("/counselling/requests/me", response_model=list[CounsellingMine])
def my_requests(
    current: CurrentUser = Depends(require_roles(UserRole.PERSONNEL)),
    db: Session = Depends(get_db),
) -> list[CounsellingMine]:
    rows = db.scalars(
        select(CounsellingRequest)
        .where(CounsellingRequest.user_id == current.id)
        .order_by(CounsellingRequest.created_at.desc())
    )
    return [
        CounsellingMine(
            request_id=r.request_id,
            status=CounsellingStatus(r.status),
            created_at=r.created_at,
            source=r.source,  # type: ignore[arg-type]
            urgency=r.urgency,  # type: ignore[arg-type]
        )
        for r in rows
    ]


@router.get("/counselling/queue", response_model=list[CounsellingQueueItem])
def counselling_queue(
    current: CurrentUser = Depends(require_roles(UserRole.COUNSELLOR, UserRole.WELFARE_OFFICER, UserRole.ORG_ADMIN)),
    db: Session = Depends(get_db),
    reason: str | None = Depends(optional_reason),
) -> list[CounsellingQueueItem]:
    write_audit(db, actor_id=current.id, action="viewed_counselling_queue", reason_code=reason)
    db.commit()
    query = select(CounsellingRequest).join(User, User.user_id == CounsellingRequest.user_id)
    if current.role != UserRole.ORG_ADMIN:
        query = query.where(User.unit_id == current.unit_id)
    rows = db.scalars(query.order_by(CounsellingRequest.created_at.desc()))
    return [
        CounsellingQueueItem(
            request_id=r.request_id,
            source=r.source,  # type: ignore[arg-type]
            status=CounsellingStatus(r.status),
            created_at=r.created_at,
            urgency=r.urgency,  # type: ignore[arg-type]
            channel=r.channel,  # type: ignore[arg-type]
            preferred_contact=r.preferred_contact,
            time_window=r.time_window,
        )
        for r in rows
    ]


@router.patch("/counselling/requests/{request_id}", response_model=CounsellingPatched)
def patch_request(
    request_id: UUID,
    body: CounsellingPatch,
    current: CurrentUser = Depends(require_roles(UserRole.COUNSELLOR)),
    db: Session = Depends(get_db),
) -> CounsellingPatched:
    row = db.get(CounsellingRequest, request_id)
    if row is None:
        raise APIError(404, "NOT_FOUND", "Request not found.")
    current_status = CounsellingStatus(row.status)
    if body.status not in TRANSITIONS[current_status] and body.status != current_status:
        raise APIError(422, "VALIDATION_ERROR", f"Cannot transition {current_status} -> {body.status}.")
    now = datetime.now(UTC)
    row.status = body.status.value
    row.updated_at = now
    if body.status == CounsellingStatus.ASSIGNED:
        row.assigned_counsellor_id = current.id
        row.assigned_at = now
    if body.status == CounsellingStatus.IN_PROGRESS and row.first_contact_at is None:
        row.first_contact_at = now
    if body.notes:
        row.counsellor_notes_encrypted = encrypt_text(body.notes)
    write_audit(
        db,
        actor_id=current.id,
        action="counselling_status_updated",
        target_user_id=row.user_id,
        reason_code=body.status.value,
    )
    db.commit()
    return CounsellingPatched(request_id=row.request_id, status=CounsellingStatus(row.status))
