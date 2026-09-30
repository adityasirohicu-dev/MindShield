"""Add email addresses for email OTP delivery."""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = "0002_user_email"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    inspector = inspect(op.get_bind())
    columns = {column["name"] for column in inspector.get_columns("users")}
    if "email" not in columns:
        op.add_column("users", sa.Column("email", sa.String(length=254), nullable=True))
    indexes = {index["name"] for index in inspector.get_indexes("users")}
    if "ix_users_email" not in indexes:
        op.create_index("ix_users_email", "users", ["email"], unique=True)


def downgrade() -> None:
    inspector = inspect(op.get_bind())
    indexes = {index["name"] for index in inspector.get_indexes("users")}
    if "ix_users_email" in indexes:
        op.drop_index("ix_users_email", table_name="users")
    columns = {column["name"] for column in inspector.get_columns("users")}
    if "email" in columns:
        op.drop_column("users", "email")
