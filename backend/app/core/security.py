import hashlib
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from cryptography.fernet import Fernet, InvalidToken
from jose import JWTError, jwt

from app.core.config import get_settings
from app.core.enums import UserRole


def _fernet() -> Fernet:
    settings = get_settings()
    key = settings.fernet_key
    if not key:
        # Stable fallback derived from SECRET_KEY so notes decrypt across restarts in local demo.
        digest = hashlib.sha256(settings.secret_key.encode()).digest()
        from base64 import urlsafe_b64encode

        key = urlsafe_b64encode(digest).decode()
        object.__setattr__(settings, "fernet_key", key)
    return Fernet(key.encode() if isinstance(key, str) else key)


def encrypt_text(value: str | None) -> str | None:
    if value is None:
        return None
    return _fernet().encrypt(value.encode()).decode()


def decrypt_text(value: str | None) -> str | None:
    if value is None:
        return None
    try:
        return _fernet().decrypt(value.encode()).decode()
    except InvalidToken:
        return value


def create_token(
    subject: UUID,
    role: UserRole,
    unit_id: UUID,
    token_type: str,
    expires_delta: timedelta,
) -> str:
    settings = get_settings()
    now = datetime.now(UTC)
    payload: dict[str, Any] = {
        "sub": str(subject),
        "role": role.value,
        "unit_id": str(unit_id),
        "typ": token_type,
        "iat": int(now.timestamp()),
        "exp": int((now + expires_delta).timestamp()),
    }
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")


def create_access_token(subject: UUID, role: UserRole, unit_id: UUID) -> str:
    minutes = get_settings().access_token_expire_minutes
    return create_token(subject, role, unit_id, "access", timedelta(minutes=minutes))


def create_refresh_token(subject: UUID, role: UserRole, unit_id: UUID) -> str:
    days = get_settings().refresh_token_expire_days
    return create_token(subject, role, unit_id, "refresh", timedelta(days=days))


def decode_token(token: str) -> dict[str, Any]:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
