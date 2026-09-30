"""Remove the legacy password credential from OTP-based accounts."""

from alembic import op
import sqlalchemy as sa

revision = "0003_remove_password_hash"
down_revision = "0002_user_email"
branch_labels = None
depends_on = None


def upgrade() -> None:
    columns = {column["name"] for column in sa.inspect(op.get_bind()).get_columns("users")}
    if "password_hash" in columns:
        with op.batch_alter_table("users") as batch:
            batch.drop_column("password_hash")


def downgrade() -> None:
    columns = {column["name"] for column in sa.inspect(op.get_bind()).get_columns("users")}
    if "password_hash" not in columns:
        with op.batch_alter_table("users") as batch:
            batch.add_column(sa.Column("password_hash", sa.String(length=255), nullable=True))
