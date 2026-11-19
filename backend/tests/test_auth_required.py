from datetime import datetime, timezone
from uuid import uuid4

from app.security import create_access_token, decode_access_token


def test_private_endpoints_require_token(client):
    assert client.get("/api/v1/trips").status_code == 401
    assert client.get("/api/v1/auth/me").status_code == 401

    response = client.post(
        "/api/v1/trips",
        json={
            "id": str(uuid4()),
            "started_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    assert response.status_code == 401


def test_invalid_token_is_rejected(client):
    response = client.get(
        "/api/v1/trips",
        headers={"Authorization": "Bearer not-a-valid-token"},
    )
    assert response.status_code == 401


def test_expired_token_is_rejected(client, auth_headers):
    valid_token = auth_headers["Authorization"].split(" ", 1)[1]
    user_id = decode_access_token(valid_token)
    expired = create_access_token(user_id, expires_minutes=-1)

    response = client.get(
        "/api/v1/trips",
        headers={"Authorization": f"Bearer {expired}"},
    )
    assert response.status_code == 401


def test_health_and_register_stay_public(client):
    assert client.get("/api/v1/health").status_code == 200
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "public@example.com", "password": "parola12345"},
    )
    assert response.status_code == 201
