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
    # Primul cont devine admin, al doilea este utilizator normal.
    register(client, "admin@example.com")
    register(client, "user@example.com")
    return (
        headers_for(client, "admin@example.com"),
        headers_for(client, "user@example.com"),
    )


def create_trip(client, headers, started_at: datetime) -> dict:
    response = client.post(
        "/api/v1/trips",
        json={"id": str(uuid4()), "started_at": started_at.isoformat()},
        headers=headers,
    )
    assert response.status_code == 201, response.text
    return response.json()


def add_point(client, headers, trip_id: str) -> None:
    response = client.post(
        f"/api/v1/trips/{trip_id}/points/batch",
        json={
            "points": [
                {
                    "id": str(uuid4()),
                    "latitude": 44.0,
                    "longitude": 26.0,
                    "recorded_at": datetime.now(timezone.utc).isoformat(),
                    "sequence_number": 0,
                }
            ]
        },
        headers=headers,
    )
    assert response.status_code == 200, response.text


def test_admin_lists_all_trips_with_owner(client):
    admin_headers, user_headers = setup_users(client)
    now = datetime.now(timezone.utc)
    user_trip = create_trip(client, user_headers, now - timedelta(minutes=10))
    admin_trip = create_trip(client, admin_headers, now - timedelta(minutes=5))

    response = client.get("/api/v1/admin/trips", headers=admin_headers)

    assert response.status_code == 200
    trips = response.json()
    assert [trip["id"] for trip in trips] == [admin_trip["id"], user_trip["id"]]
    by_id = {trip["id"]: trip["user_email"] for trip in trips}
    assert by_id[user_trip["id"]] == "user@example.com"
    assert by_id[admin_trip["id"]] == "admin@example.com"


def test_regular_user_cannot_list_all_trips(client):
    _, user_headers = setup_users(client)
    assert (
        client.get("/api/v1/admin/trips", headers=user_headers).status_code
        == 403
    )


def test_admin_endpoints_require_authentication(client):
    assert client.get("/api/v1/admin/trips").status_code == 401


def test_admin_can_read_another_users_points(client):
    admin_headers, user_headers = setup_users(client)
    trip = create_trip(
        client, user_headers, datetime.now(timezone.utc) - timedelta(minutes=5)
    )
    add_point(client, user_headers, trip["id"])

    response = client.get(
        f"/api/v1/admin/trips/{trip['id']}/points", headers=admin_headers
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_regular_user_cannot_read_other_users_points_through_admin(client):
    _, user_headers = setup_users(client)
    trip = create_trip(
        client, user_headers, datetime.now(timezone.utc) - timedelta(minutes=5)
    )

    response = client.get(
        f"/api/v1/admin/trips/{trip['id']}/points", headers=user_headers
    )
    assert response.status_code == 403


def test_admin_points_for_missing_trip_returns_404(client):
    admin_headers, _ = setup_users(client)
    response = client.get(
        f"/api/v1/admin/trips/{uuid4()}/points", headers=admin_headers
    )
    assert response.status_code == 404
