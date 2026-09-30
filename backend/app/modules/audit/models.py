from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.db.base import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    actor_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False, index=True)
    action: Mapped[str] = mapped_column(String(80), nullable=False)
    target_user_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    reason_code: Mapped[str | None] = mapped_column(String(120), nullable=True)
    metadata_json: Mapped[str | None] = mapped_column(Text, nullable=True)
