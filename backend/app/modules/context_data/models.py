from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.db.base import Base


class DutyContext(Base):
    __tablename__ = "duty_contexts"

    context_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False, index=True)
    leave_days_recent: Mapped[int] = mapped_column(Integer, default=0)
    deployment_status: Mapped[str] = mapped_column(String(24), nullable=False)
    duty_hours_weekly: Mapped[float] = mapped_column(Float, default=0)
    transfer_count_recent: Mapped[int] = mapped_column(Integer, default=0)
    training_load: Mapped[float] = mapped_column(Float, default=0)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
