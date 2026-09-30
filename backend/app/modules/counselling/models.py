from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.enums import CounsellingSource, CounsellingStatus
from app.db.base import Base


class CounsellingRequest(Base):
    __tablename__ = "counselling_requests"

    request_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False, index=True)
    source: Mapped[str] = mapped_column(String(24), default=CounsellingSource.SELF_REQUESTED.value)
    status: Mapped[str] = mapped_column(String(24), default=CounsellingStatus.REQUESTED.value)
    assigned_counsellor_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("users.user_id"), nullable=True
    )
    preferred_contact: Mapped[str | None] = mapped_column(String(80), nullable=True)
    note_encrypted: Mapped[str | None] = mapped_column(String, nullable=True)
    channel: Mapped[str | None] = mapped_column(String(32), nullable=True)
    time_window: Mapped[str | None] = mapped_column(String(80), nullable=True)
    urgency: Mapped[str | None] = mapped_column(String(24), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    assigned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    first_contact_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    counsellor_notes_encrypted: Mapped[str | None] = mapped_column(String, nullable=True)
