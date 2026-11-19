from sqlalchemy import select

from app.models import User
from app.security import decode_access_token, verify_password

REGISTER_URL = "/api/v1/auth/register"
LOGIN_URL = "/api/v1/auth/login"
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


def login(client, email: str = "user@example.com", password: str = PASSWORD):
    return client.post(
        LOGIN_URL, json={"email": email, "password": password}
    )


def test_me_returns_current_user(client, auth_headers):
    response = client.get("/api/v1/auth/me", headers=auth_headers)
    assert response.status_code == 200
    assert response.json()["email"] == "test-user@example.com"


def test_login_returns_token(client):
    assert register(client).status_code == 201

    response = login(client)

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["email"] == "user@example.com"
    assert decode_access_token(body["access_token"]) == body["user"]["id"]


def test_login_email_is_case_insensitive(client):
    assert register(client).status_code == 201
    assert login(client, email="USER@example.com").status_code == 200


def test_login_with_wrong_password_is_rejected(client):
    assert register(client).status_code == 201
    response = login(client, password="parolagresita")
    assert response.status_code == 401
    assert response.json()["detail"] == "Email sau parolă incorecte."


def test_login_with_unknown_email_has_same_message(client):
    assert register(client).status_code == 201
    response = login(client, email="unknown@example.com")
    assert response.status_code == 401
    assert response.json()["detail"] == "Email sau parolă incorecte."


def test_password_is_hashed_in_database(client, session_factory):
    assert register(client).status_code == 201

    with session_factory() as db:
        user = db.scalar(select(User))
        assert user is not None
        assert user.password_hash != PASSWORD
        assert user.password_hash is not None
        assert user.password_hash.startswith("$2")
        assert verify_password(PASSWORD, user.password_hash)
