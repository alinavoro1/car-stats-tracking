from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest


@pytest.fixture(autouse=True)
def _authenticated_client(client, auth_headers):
    client.headers.update(auth_headers)


def now() -> datetime:
    return datetime.now(timezone.utc)


def iso(value: datetime) -> str:
    return value.isoformat()


def trip_payload(started_at: datetime | None = None) -> dict:
    return {
        "id": str(uuid4()),
        "started_at": iso(started_at or now()),
    }


def point_payload(
    sequence: int,
    recorded_at: datetime | None = None,
    **overrides,
) -> dict:
    data = {
        "id": str(uuid4()),
        "latitude": 44.0,
        "longitude": 26.0,
        "speed_mps": 10.0,
        "accuracy_meters": 5.0,
        "altitude_meters": 90.0,
        "recorded_at": iso(recorded_at or now()),
        "sequence_number": sequence,
    }
    data.update(overrides)
    return data


def create_trip(client, started_at: datetime | None = None) -> dict:
    response = client.post("/api/v1/trips", json=trip_payload(started_at))
    assert response.status_code == 201
    return response.json()


def completion_payload(started_at: datetime) -> dict:
    ended_at = started_at + timedelta(minutes=10)
    return {
        "ended_at": iso(ended_at),
        "distance_meters": 5000.0,
        "average_speed_mps": 12.5,
        "max_speed_mps": 25.0,
        "moving_duration_seconds": 400,
        "total_duration_seconds": 600,
    }


def test_health(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_openapi_is_available(client):
    assert client.get("/openapi.json").status_code == 200


def test_create_trip_is_idempotent(client):
    payload = trip_payload()
    first = client.post("/api/v1/trips", json=payload)
    second = client.post("/api/v1/trips", json=payload)

    assert first.status_code == 201
    assert second.status_code == 201
    assert second.json()["id"] == payload["id"]
    assert len(client.get("/api/v1/trips").json()) == 1


def test_second_active_trip_is_rejected(client):
    create_trip(client)
    response = client.post("/api/v1/trips", json=trip_payload())
    assert response.status_code == 409


def test_started_at_requires_timezone(client):
    payload = {
        "id": str(uuid4()),
        "started_at": datetime(2026, 1, 1, 12, 0).isoformat(),
    }
    response = client.post("/api/v1/trips", json=payload)
    assert response.status_code == 422


def test_invalid_coordinates_are_rejected(client):
    trip = create_trip(client)
    response = client.post(
        f"/api/v1/trips/{trip['id']}/points/batch",
        json={"points": [point_payload(0, latitude=91)]},
    )
    assert response.status_code == 422


def test_batch_is_saved_and_retry_does_not_duplicate(client):
    trip = create_trip(client)
    base_time = now()
    points = [
        point_payload(i, recorded_at=base_time + timedelta(seconds=i * 5))
        for i in range(3)
    ]

    first = client.post(
        f"/api/v1/trips/{trip['id']}/points/batch", json={"points": points}
    )
    second = client.post(
        f"/api/v1/trips/{trip['id']}/points/batch", json={"points": points}
    )

    assert first.status_code == 200
    assert first.json() == {"received": 3, "inserted": 3, "duplicates": 0}
    assert second.status_code == 200
    assert second.json() == {"received": 3, "inserted": 0, "duplicates": 3}

    stored = client.get(f"/api/v1/trips/{trip['id']}/points").json()
    assert [point["sequence_number"] for point in stored] == [0, 1, 2]


def test_batch_size_is_limited(client):
    trip = create_trip(client)
    too_many = [point_payload(i) for i in range(501)]
    response = client.post(
        f"/api/v1/trips/{trip['id']}/points/batch",
        json={"points": too_many},
    )
    empty = client.post(
        f"/api/v1/trips/{trip['id']}/points/batch", json={"points": []}
    )

    assert response.status_code == 422
    assert empty.status_code == 422


def test_complete_trip_is_idempotent(client):
    started_at = now() - timedelta(minutes=10)
    trip = create_trip(client, started_at)
    payload = completion_payload(started_at)

    first = client.post(f"/api/v1/trips/{trip['id']}/complete", json=payload)
    second = client.post(f"/api/v1/trips/{trip['id']}/complete", json=payload)

    assert first.status_code == 200
    assert first.json()["status"] == "completed"
    assert second.status_code == 200
    assert second.json()["distance_meters"] == 5000.0
    assert second.json()["ended_at"] is not None


def test_completion_before_start_is_rejected(client):
    started_at = now()
    trip = create_trip(client, started_at)
    payload = completion_payload(started_at)
    payload["ended_at"] = iso(started_at - timedelta(minutes=1))

    response = client.post(f"/api/v1/trips/{trip['id']}/complete", json=payload)
    assert response.status_code == 422


def test_trips_are_listed_newest_first(client):
    older_start = now() - timedelta(hours=2)
    older = create_trip(client, older_start)
    client.post(
        f"/api/v1/trips/{older['id']}/complete",
        json=completion_payload(older_start),
    )
    newer = create_trip(client, now() - timedelta(minutes=5))

    trips = client.get("/api/v1/trips").json()

    assert [trip["id"] for trip in trips] == [newer["id"], older["id"]]


def test_missing_trip_returns_404(client):
    missing_id = str(uuid4())
    assert client.get(f"/api/v1/trips/{missing_id}").status_code == 404
    assert client.get(f"/api/v1/trips/{missing_id}/points").status_code == 404
    assert (
        client.post(
            f"/api/v1/trips/{missing_id}/points/batch",
            json={"points": [point_payload(0)]},
        ).status_code
        == 404
    )


def test_delete_trip_removes_it(client):
    trip = create_trip(client)
    assert client.delete(f"/api/v1/trips/{trip['id']}").status_code == 204
    assert client.get(f"/api/v1/trips/{trip['id']}").status_code == 404
    assert client.get("/api/v1/trips").json() == []
