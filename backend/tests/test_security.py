from datetime import datetime, timedelta, timezone

import jwt
import pytest

from app.config import get_settings
from app.security import ALGORITHM, create_access_token, decode_access_token


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


def test_token_without_subject_is_rejected():
    token = jwt.encode(
        {"exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
        get_settings().secret_key,
        algorithm=ALGORITHM,
    )
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token(token)
