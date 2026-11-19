from datetime import datetime, timedelta, timezone

import jwt

from app.config import get_settings

ALGORITHM = "HS256"


def create_access_token(
    user_id: int,
    expires_minutes: int | None = None,
) -> str:
    settings = get_settings()
    minutes = (
        expires_minutes
        if expires_minutes is not None
        else settings.access_token_expire_minutes
    )
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=minutes),
    }
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def decode_access_token(token: str) -> int:
    """Returnează ID-ul utilizatorului sau ridică InvalidTokenError."""
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        return int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, TypeError, ValueError) as error:
        raise jwt.InvalidTokenError("Token invalid.") from error
