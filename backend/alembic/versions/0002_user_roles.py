"""add user roles

Revision ID: 0002_user_roles
Revises: 0001_initial
Create Date: 2026-11-19
"""

import sqlalchemy as sa
from alembic import op

revision = "0002_user_roles"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("role", sa.String(length=20), nullable=True))
    op.execute("UPDATE users SET role = 'user' WHERE role IS NULL")
    op.alter_column("users", "role", nullable=False)
    op.create_check_constraint(
        "ck_users_role", "users", "role IN ('user', 'admin')"
    )


def downgrade() -> None:
    op.drop_constraint("ck_users_role", "users", type_="check")
    op.drop_column("users", "role")
