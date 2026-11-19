from datetime import datetime, timezone
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

MAX_BATCH_SIZE = 500
# 100 m/s (~360 km/h) este o limită superioară rezonabilă pentru o mașină.
MAX_SPEED_MPS = 100.0


def to_utc(value: datetime) -> datetime:
    """Respinge timestamp-urile fără fus orar și le normalizează la UTC."""
    if value.tzinfo is None or value.utcoffset() is None:
        raise ValueError("timestamp-ul trebuie să includă fusul orar (ISO 8601)")
    return value.astimezone(timezone.utc)


class TripCreate(BaseModel):
    id: UUID
    started_at: datetime

    _validate_started_at = field_validator("started_at")(to_utc)


class TripComplete(BaseModel):
    ended_at: datetime
    distance_meters: float = Field(ge=0)
    average_speed_mps: float = Field(ge=0, le=MAX_SPEED_MPS)
    max_speed_mps: float = Field(ge=0, le=MAX_SPEED_MPS)
    moving_duration_seconds: int = Field(ge=0)
    total_duration_seconds: int = Field(ge=0)

    _validate_ended_at = field_validator("ended_at")(to_utc)


class GPSPointIn(BaseModel):
    id: UUID
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    speed_mps: float | None = Field(default=None, ge=0, le=MAX_SPEED_MPS)
    accuracy_meters: float | None = Field(default=None, ge=0)
    altitude_meters: float | None = None
    recorded_at: datetime
    sequence_number: int = Field(ge=0)

    _validate_recorded_at = field_validator("recorded_at")(to_utc)


class GPSPointsBatchIn(BaseModel):
    points: list[GPSPointIn] = Field(min_length=1, max_length=MAX_BATCH_SIZE)


class GPSPointOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    latitude: float
    longitude: float
    speed_mps: float | None
    accuracy_meters: float | None
    altitude_meters: float | None
    recorded_at: datetime
    sequence_number: int


class TripOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    started_at: datetime
    ended_at: datetime | None
    status: Literal["active", "completed", "cancelled", "interrupted"]
    distance_meters: float
    average_speed_mps: float
    max_speed_mps: float
    moving_duration_seconds: int
    total_duration_seconds: int


class BatchResult(BaseModel):
    received: int
    inserted: int
    duplicates: int
