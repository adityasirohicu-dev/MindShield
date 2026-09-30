from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON, Uuid

from app.db.base import Base


class CheckIn(Base):
    __tablename__ = "checkins"
    __table_args__ = (
        UniqueConstraint("user_id", "client_submitted_at", name="uq_checkin_user_client_ts"),
    )

    checkin_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False, index=True)
    mood_score: Mapped[int] = mapped_column(Integer, nullable=False)
    stress_score: Mapped[int] = mapped_column(Integer, nullable=False)
    recovery_score: Mapped[int] = mapped_column(Integer, nullable=False)
    note_encrypted: Mapped[str | None] = mapped_column(String, nullable=True)
    readiness_state: Mapped[str | None] = mapped_column(String(40), nullable=True)
    duty_stress_10: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sleep_hours: Mapped[float | None] = mapped_column(Float, nullable=True)
    rest_quality: Mapped[str | None] = mapped_column(String(20), nullable=True)
    friction_factors: Mapped[list | None] = mapped_column(JSON, nullable=True)
    client_submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
