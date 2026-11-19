from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import GPSPoint, Trip, User
from app.schemas import (
    BatchResult,
    GPSPointOut,
    GPSPointsBatchIn,
    TripComplete,
    TripCreate,
    TripOut,
)
from app.security import get_current_user

router = APIRouter(prefix="/trips", tags=["trips"])


def get_trip_for_user_or_404(
    db: Session, trip_id: str, user_id: int
) -> Trip:
    trip = db.get(Trip, trip_id)
    if trip is None or trip.user_id != user_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Călătoria nu există.")
    return trip


def as_utc(value: datetime) -> datetime:
    """Some drivers (notably SQLite) return naive datetimes."""
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


@router.post("", response_model=TripOut, status_code=status.HTTP_201_CREATED)
def create_trip(
    payload: TripCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Trip:
    trip_id = str(payload.id)

    # Retrimiterea aceleiași cereri (retry) nu creează o călătorie nouă.
    existing = db.get(Trip, trip_id)
    if existing is not None:
        if existing.user_id != current_user.id:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "ID-ul călătoriei este deja folosit.",
            )
        return existing

    active = db.scalar(
        select(Trip).where(
            Trip.status == "active", Trip.user_id == current_user.id
        )
    )
    if active is not None:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Există deja o călătorie activă.",
        )

    trip = Trip(
        id=trip_id,
        user_id=current_user.id,
        started_at=payload.started_at,
        status="active",
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return trip


@router.get("", response_model=list[TripOut])
def list_trips(
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Trip]:
    limit = max(1, min(limit, 500))
    return list(
        db.scalars(
            select(Trip)
            .where(Trip.user_id == current_user.id)
            .order_by(Trip.started_at.desc())
            .limit(limit)
        )
    )


@router.get("/{trip_id}", response_model=TripOut)
def get_trip(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Trip:
    return get_trip_for_user_or_404(db, trip_id, current_user.id)


@router.get("/{trip_id}/points", response_model=list[GPSPointOut])
def list_points(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[GPSPoint]:
    trip = get_trip_for_user_or_404(db, trip_id, current_user.id)
    return trip.points


@router.post("/{trip_id}/points/batch", response_model=BatchResult)
def add_points_batch(
    trip_id: str,
    payload: GPSPointsBatchIn,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> BatchResult:
    trip = get_trip_for_user_or_404(db, trip_id, current_user.id)
    if trip.status == "cancelled":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Nu se pot adăuga puncte unei călătorii anulate.",
        )

    point_ids = [str(point.id) for point in payload.points]
    existing_ids = set(
        db.scalars(
            select(GPSPoint.id).where(
                GPSPoint.trip_id == trip_id, GPSPoint.id.in_(point_ids)
            )
        )
    )
    new_points = [
        GPSPoint(
            id=str(point.id),
            trip_id=trip_id,
            latitude=point.latitude,
            longitude=point.longitude,
            speed_mps=point.speed_mps,
            accuracy_meters=point.accuracy_meters,
            altitude_meters=point.altitude_meters,
            recorded_at=point.recorded_at,
            sequence_number=point.sequence_number,
        )
        for point in payload.points
        if str(point.id) not in existing_ids
    ]

    if new_points:
        db.add_all(new_points)
        try:
            db.commit()
        except Exception:
            db.rollback()
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                "Batch-ul conține puncte duplicate sau cu secvență duplicată.",
            )

    return BatchResult(
        received=len(payload.points),
        inserted=len(new_points),
        duplicates=len(payload.points) - len(new_points),
    )


@router.post("/{trip_id}/complete", response_model=TripOut)
def complete_trip(
    trip_id: str,
    payload: TripComplete,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Trip:
    trip = get_trip_for_user_or_404(db, trip_id, current_user.id)

    if trip.status == "cancelled":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Călătoria a fost anulată.",
        )
    # Finalizarea repetată (retry) este acceptată fără să suprascrie datele.
    if trip.status == "completed":
        return trip

    if payload.ended_at < as_utc(trip.started_at):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            "Ora de finalizare nu poate fi înainte de ora de început.",
        )

    trip.ended_at = payload.ended_at
    trip.distance_meters = payload.distance_meters
    trip.average_speed_mps = payload.average_speed_mps
    trip.max_speed_mps = payload.max_speed_mps
    trip.moving_duration_seconds = payload.moving_duration_seconds
    trip.total_duration_seconds = payload.total_duration_seconds
    trip.status = "completed"
    db.commit()
    db.refresh(trip)
    return trip


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trip(
    trip_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    trip = get_trip_for_user_or_404(db, trip_id, current_user.id)
    db.delete(trip)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
