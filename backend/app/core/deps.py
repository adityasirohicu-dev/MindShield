from datetime import UTC, datetime
from uuid import UUID

from fastapi import Depends, Header
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.core.errors import APIError
from app.core.security import decode_token
from app.db.session import get_db
from app.modules.auth_consent.models import User

bearer = HTTPBearer(auto_error=False)


class CurrentUser:
    def __init__(self, user: User, role: UserRole, unit_id: UUID) -> None:
        self.user = user
        self.role = role
        self.unit_id = unit_id
        self.id = user.user_id


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> CurrentUser:
    if credentials is None:
        raise APIError(401, "UNAUTHORIZED", "Missing bearer token.")
    try:
        payload = decode_token(credentials.credentials)
    except ValueError as exc:
        raise APIError(401, "UNAUTHORIZED", "Invalid or expired token.") from exc
    if payload.get("typ") != "access":
        raise APIError(401, "UNAUTHORIZED", "Access token required.")
    user = db.get(User, UUID(payload["sub"]))
    if user is None or user.status != "active":
        raise APIError(401, "UNAUTHORIZED", "User not found or inactive.")
    return CurrentUser(user=user, role=UserRole(payload["role"]), unit_id=UUID(payload["unit_id"]))


def require_roles(*roles: UserRole):
    def checker(current: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if current.role not in roles:
            raise APIError(403, "FORBIDDEN", "You do not have permission for this action.")
        return current

    return checker


def optional_reason(x_access_reason: str | None = Header(default=None)) -> str | None:
    return x_access_reason
