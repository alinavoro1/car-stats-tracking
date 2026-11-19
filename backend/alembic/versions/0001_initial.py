"""create users, trips and gps_points

Revision ID: 0001_initial
Revises:
Create Date: 2026-11-19
"""

import sqlalchemy as sa
from alembic import op

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("email", name="uq_users_email"),
    )

    op.create_table(
        "trips",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("distance_meters", sa.Float(), nullable=False),
        sa.Column("average_speed_mps", sa.Float(), nullable=False),
        sa.Column("max_speed_mps", sa.Float(), nullable=False),
        sa.Column("moving_duration_seconds", sa.Integer(), nullable=False),
        sa.Column("total_duration_seconds", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('active', 'completed', 'cancelled', 'interrupted')",
            name="ck_trips_status",
        ),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_trips_user_id", ondelete="CASCADE"
        ),
    )
    op.create_index("ix_trips_user_id", "trips", ["user_id"], unique=False)
    op.create_index("ix_trips_status", "trips", ["status"], unique=False)

    op.create_table(
        "gps_points",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("trip_id", sa.String(length=36), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("speed_mps", sa.Float(), nullable=True),
        sa.Column("accuracy_meters", sa.Float(), nullable=True),
        sa.Column("altitude_meters", sa.Float(), nullable=True),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("sequence_number", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ["trip_id"],
            ["trips.id"],
            name="fk_gps_points_trip_id",
            ondelete="CASCADE",
        ),
        sa.UniqueConstraint(
            "trip_id", "sequence_number", name="uq_gps_points_trip_sequence"
        ),
    )
    op.create_index("ix_gps_points_trip_id", "gps_points", ["trip_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_gps_points_trip_id", table_name="gps_points")
    op.drop_table("gps_points")
    op.drop_index("ix_trips_status", table_name="trips")
    op.drop_index("ix_trips_user_id", table_name="trips")
    op.drop_table("trips")
    op.drop_table("users")
