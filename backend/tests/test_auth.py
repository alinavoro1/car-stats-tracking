from sqlalchemy import select

from app.models import User
from app.security import verify_password

REGISTER_URL = "/api/v1/auth/register"
PASSWORD = "parola12345"


def register(client, email: str = "user@example.com", password: str = PASSWORD):
    return client.post(
        REGISTER_URL, json={"email": email, "password": password}
    )


def test_register_creates_user(client):
    response = register(client)
    assert response.status_code == 201
    body = response.json()
    assert body["email"] == "user@example.com"
    assert "password" not in body
    assert "password_hash" not in body


def test_email_is_normalized(client):
    response = register(client, email="User@Example.com")
    assert response.status_code == 201
    assert response.json()["email"] == "user@example.com"


def test_duplicate_email_is_rejected(client):
    assert register(client).status_code == 201
    duplicate = register(client, email="USER@example.com")
    assert duplicate.status_code == 409


def test_invalid_email_is_rejected(client):
    assert register(client, email="not-an-email").status_code == 422


def test_short_password_is_rejected(client):
    assert register(client, password="scurt").status_code == 422


def test_password_over_72_bytes_is_rejected(client):
    # 40 de caractere multibyte depășesc limita de 72 de octeți.
    assert register(client, password="ă" * 40).status_code == 422


def test_password_is_hashed_in_database(client, session_factory):
    assert register(client).status_code == 201

    with session_factory() as db:
        user = db.scalar(select(User))
        assert user is not None
        assert user.password_hash != PASSWORD
        assert user.password_hash is not None
        assert user.password_hash.startswith("$2")
        assert verify_password(PASSWORD, user.password_hash)
