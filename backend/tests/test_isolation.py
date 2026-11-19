from datetime import datetime, timedelta, timezone
from uuid import uuid4

PASSWORD = "parola12345"


def register(client, email: str) -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": PASSWORD},
    )
    assert response.status_code == 201, response.text


def headers_for(client, email: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": PASSWORD},
    )
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def setup_users(client):
    # Primul cont devine admin; următoarele două sunt utilizatori normali.
    register(client, "admin@example.com")
    register(client, "a@example.com")
    register(client, "b@example.com")
    return (
        headers_for(client, "a@example.com"),
        headers_for(client, "b@example.com"),
        headers_for(client, "admin@example.com"),
    )


def create_trip(client, headers) -> dict:
    response = client.post(
        "/api/v1/trips",
        json={
            "id": str(uuid4()),
            "started_at": (
                datetime.now(timezone.utc) - timedelta(minutes=1)
            ).isoformat(),
        },
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def point_payload(sequence: int = 0) -> dict:
    return {
        "id": str(uuid4()),
        "latitude": 44.0,
        "longitude": 26.0,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "sequence_number": sequence,
    }


def completion_payload() -> dict:
    return {
        "ended_at": datetime.now(timezone.utc).isoformat(),
        "distance_meters": 100.0,
        "average_speed_mps": 5.0,
        "max_speed_mps": 10.0,
        "moving_duration_seconds": 20,
        "total_duration_seconds": 60,
    }


def test_user_cannot_read_another_users_trip(client):
    user_a, user_b, admin = setup_users(client)
    trip = create_trip(client, user_a)

    assert client.get(f"/api/v1/trips/{trip['id']}", headers=user_a).status_code == 200
    assert client.get(f"/api/v1/trips/{trip['id']}", headers=user_b).status_code == 404
    assert (
        client.get(f"/api/v1/trips/{trip['id']}/points", headers=user_b).status_code
        == 404
    )
    # Adminul folosește endpointurile de administrare, nu cele normale.
    assert client.get(f"/api/v1/trips/{trip['id']}", headers=admin).status_code == 404


def test_list_returns_only_own_trips(client):
    user_a, user_b, _ = setup_users(client)
    trip = create_trip(client, user_a)

    trips_a = client.get("/api/v1/trips", headers=user_a).json()
    trips_b = client.get("/api/v1/trips", headers=user_b).json()

    assert [item["id"] for item in trips_a] == [trip["id"]]
    assert trips_b == []


def test_user_cannot_modify_another_users_trip(client):
    user_a, user_b, _ = setup_users(client)
    trip = create_trip(client, user_a)
    trip_id = trip["id"]

    assert (
        client.post(
            f"/api/v1/trips/{trip_id}/points/batch",
            json={"points": [point_payload()]},
            headers=user_b,
        ).status_code
        == 404
    )
    assert (
        client.post(
            f"/api/v1/trips/{trip_id}/complete",
            json=completion_payload(),
            headers=user_b,
        ).status_code
        == 404
    )
    assert client.delete(f"/api/v1/trips/{trip_id}", headers=user_b).status_code == 404

    assert client.get(f"/api/v1/trips/{trip_id}", headers=user_a).status_code == 200


def test_each_user_can_have_one_active_trip(client):
    user_a, user_b, _ = setup_users(client)

    create_trip(client, user_a)
    create_trip(client, user_b)

    second_for_a = client.post(
        "/api/v1/trips",
        json={
            "id": str(uuid4()),
            "started_at": datetime.now(timezone.utc).isoformat(),
        },
        headers=user_a,
    )
    assert second_for_a.status_code == 409


def test_trip_id_cannot_be_reused_across_users(client):
    user_a, user_b, _ = setup_users(client)
    trip = create_trip(client, user_a)

    response = client.post(
        "/api/v1/trips",
        json={
            "id": trip["id"],
            "started_at": datetime.now(timezone.utc).isoformat(),
        },
        headers=user_b,
    )
    assert response.status_code == 409
