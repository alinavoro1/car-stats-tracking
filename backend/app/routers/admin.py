from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import GPSPoint, Trip, User
from app.schemas import AdminTripOut, GPSPointOut, TripOut
from app.security import require_admin

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/trips", response_model=list[AdminTripOut])
def list_all_trips(
    limit: int = 200,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
) -> list[AdminTripOut]:
    limit = max(1, min(limit, 500))
    rows = db.execute(
        select(Trip, User.email)
        .join(User, Trip.user_id == User.id)
        .order_by(Trip.started_at.desc())
        .limit(limit)
    ).all()

    return [
        AdminTripOut(
            **TripOut.model_validate(trip).model_dump(),
            user_email=email,
        )
        for trip, email in rows
    ]


@router.get("/trips/{trip_id}/points", response_model=list[GPSPointOut])
def list_trip_points(
    trip_id: str,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
) -> list[GPSPoint]:
    trip = db.get(Trip, trip_id)
    if trip is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Călătoria nu există.")
    return trip.points
