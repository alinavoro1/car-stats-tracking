from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi import HTTPException

from app.config import get_settings
from app.models import User
from app.security import (
    ALGORITHM,
    create_access_token,
    decode_access_token,
    require_admin,
)


def test_token_round_trip():
    token = create_access_token(42)
    assert decode_access_token(token) == 42


def test_expired_token_is_rejected():
    token = create_access_token(42, expires_minutes=-1)
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)


def test_token_signed_with_other_secret_is_rejected():
    payload = {
        "sub": "1",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=5),
    }
    token = jwt.encode(
        payload,
        "other-secret-long-enough-for-hs256-123456",
        algorithm=ALGORITHM,
    )
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)


def test_require_admin_accepts_admin():
    admin = User(email="admin@example.com", role="admin")
    assert require_admin(current_user=admin) is admin


def test_require_admin_rejects_regular_user():
    user = User(email="user@example.com", role="user")
    with pytest.raises(HTTPException) as error:
        require_admin(current_user=user)
    assert error.value.status_code == 403


def test_token_without_subject_is_rejected():
    token = jwt.encode(
        {"exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        get_settings().secret_key,
        algorithm=ALGORITHM,
    )
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)
