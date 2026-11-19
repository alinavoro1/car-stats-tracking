from datetime import datetime, timezone

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base

TRIP_STATUSES = ("active", "completed", "cancelled", "interrupted")


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    # Rămâne gol cât timp aplicația folosește un singur utilizator implicit.
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    trips: Mapped[list["Trip"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class Trip(Base):
    """Distanța este în metri, viteza în m/s, duratele în secunde."""

    __tablename__ = "trips"
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'completed', 'cancelled', 'interrupted')",
            name="ck_trips_status",
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="active", index=True
    )

    distance_meters: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    average_speed_mps: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    max_speed_mps: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    moving_duration_seconds: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )
    total_duration_seconds: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False
    )

    user: Mapped[User] = relationship(back_populates="trips")
    points: Mapped[list["GPSPoint"]] = relationship(
        back_populates="trip",
        cascade="all, delete-orphan",
        order_by="GPSPoint.sequence_number",
        passive_deletes=True,
    )


class GPSPoint(Base):
    """Un punct GPS colectat în timpul unei călătorii."""

    __tablename__ = "gps_points"
    __table_args__ = (
        UniqueConstraint(
            "trip_id", "sequence_number", name="uq_gps_points_trip_sequence"
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    trip_id: Mapped[str] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    speed_mps: Mapped[float | None] = mapped_column(Float)
    accuracy_meters: Mapped[float | None] = mapped_column(Float)
    altitude_meters: Mapped[float | None] = mapped_column(Float)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    sequence_number: Mapped[int] = mapped_column(Integer, nullable=False)

    trip: Mapped[Trip] = relationship(back_populates="points")
