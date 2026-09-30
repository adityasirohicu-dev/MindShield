from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import Uuid

from app.core.enums import ConsentDataType, ConsentStatus, UserRole, UserStatus
from app.db.base import Base


class Unit(Base):
    __tablename__ = "units"

    unit_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    users: Mapped[list["User"]] = relationship(back_populates="unit")


class User(Base):
    __tablename__ = "users"

    user_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    credential: Mapped[str] = mapped_column(String(120), unique=True, nullable=False, index=True)
    email: Mapped[str | None] = mapped_column(String(254), unique=True, nullable=True, index=True)
    display_name: Mapped[str] = mapped_column(String(120), nullable=False)
    rank_label: Mapped[str] = mapped_column(String(80), default="Operator")
    role: Mapped[str] = mapped_column(String(32), nullable=False, default=UserRole.PERSONNEL.value)
    unit_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("units.unit_id"), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=UserStatus.ACTIVE.value)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    exclude_sensor_from_scoring: Mapped[bool] = mapped_column(default=False)

    unit: Mapped[Unit] = relationship(back_populates="users")
    consents: Mapped[list["ConsentRecord"]] = relationship(back_populates="user")


class ConsentRecord(Base):
    __tablename__ = "consent_records"
    __table_args__ = (UniqueConstraint("user_id", "data_type", name="uq_consent_user_type"),)

    consent_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.user_id"), nullable=False)
    data_type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=ConsentStatus.REVOKED.value)
    granted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped[User] = relationship(back_populates="consents")
