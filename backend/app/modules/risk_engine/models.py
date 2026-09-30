from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import JSON, Uuid

from app.core.enums import ReviewStatus, RiskLevel
from app.db.base import Base


class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    assessment_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False, index=True)
    risk_level: Mapped[str] = mapped_column(String(16), nullable=False, default=RiskLevel.LOW.value, index=True)
    score: Mapped[float] = mapped_column(Float, nullable=False)
    contributing_factors: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    recommended_actions: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    forecast_text: Mapped[str] = mapped_column(String(500), default="")
    wellness_index: Mapped[int] = mapped_column(default=70)
    model_version: Mapped[str] = mapped_column(String(32), default="rules-v1")
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    reviewed_by: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=True)
    review_status: Mapped[str] = mapped_column(String(16), default=ReviewStatus.PENDING.value)
    review_notes_encrypted: Mapped[str | None] = mapped_column(String, nullable=True)
    action_taken: Mapped[str | None] = mapped_column(String(120), nullable=True)
    officer_feedback: Mapped[str | None] = mapped_column(String(32), nullable=True)
