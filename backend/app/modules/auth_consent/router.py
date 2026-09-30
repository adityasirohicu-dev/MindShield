from datetime import UTC, datetime, timedelta
from email.message import EmailMessage
from smtplib import SMTP, SMTP_SSL
from threading import Lock
from uuid import UUID
import secrets

from fastapi import APIRouter, Depends, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.deps import CurrentUser, get_current_user
from app.core.enums import UserRole, UserStatus
from app.core.errors import APIError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.db.session import get_db
from app.modules.auth_consent.models import Unit, User
from app.modules.auth_consent.schemas import (
    ConsentItem,
    ConsentUpdate,
    LoginRequest,
    LoginResponse,
    OtpRequest,
    OtpResponse,
    RefreshRequest,
    RegisterRequest,
    RegisterResponse,
    TokenResponse,
)
from app.modules.auth_consent.service import ensure_consent_rows, list_consent, upsert_consent

router = APIRouter(tags=["auth-consent"])
_otp_codes: dict[str, tuple[str, datetime]] = {}
_otp_lock = Lock()
_auth_attempts: dict[str, list[datetime]] = {}


def _check_auth_rate(request: Request) -> None:
    now = datetime.now(UTC)
    client_ip = request.client.host if request.client else "unknown"
    key = f"{client_ip}:{request.url.path}"
    with _otp_lock:
        attempts = [stamp for stamp in _auth_attempts.get(key, []) if now - stamp < timedelta(minutes=1)]
        if len(attempts) >= 5:
            raise APIError(429, "RATE_LIMITED", "Too many authentication attempts. Try again in one minute.")
        attempts.append(now)
        _auth_attempts[key] = attempts


@router.post("/auth/otp", response_model=OtpResponse)
def send_otp(body: OtpRequest, request: Request, db: Session = Depends(get_db)) -> OtpResponse:
    """Issue a local presentation code, or deliver a short-lived code over configured SMTP."""
    settings = get_settings()
    _check_auth_rate(request)
    user = db.scalars(select(User).where(User.credential == body.credential)).first()
    if body.purpose == "login" and user is None:
        raise APIError(404, "NOT_FOUND", "No account was found for that service ID.")
    email = body.email if body.purpose == "register" else (user.email if user else None)
    configured_smtp = bool(settings.smtp_host and settings.smtp_from_email and email)
    if not configured_smtp and settings.app_env != "local":
        raise APIError(503, "EMAIL_NOT_CONFIGURED", "Email OTP delivery is not configured for this server.")
    code = f"{secrets.randbelow(1_000_000):06d}" if configured_smtp else settings.demo_otp
    expires = datetime.now(UTC) + timedelta(minutes=10)
    with _otp_lock:
        _otp_codes[body.credential.casefold()] = (code, expires)

    if configured_smtp:
        message = EmailMessage()
        message["Subject"] = "Your Mind Shield verification code"
        message["From"] = settings.smtp_from_email
        message["To"] = email
        message.set_content(f"Your Mind Shield verification code is {code}. It expires in 10 minutes.")
        try:
            if settings.smtp_port == 465:
                with SMTP_SSL(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
                    if settings.smtp_username:
                        smtp.login(settings.smtp_username, settings.smtp_password)
                    smtp.send_message(message)
            else:
                with SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
                    if settings.smtp_starttls:
                        smtp.starttls()
                    if settings.smtp_username:
                        smtp.login(settings.smtp_username, settings.smtp_password)
                    smtp.send_message(message)
        except Exception as exc:
            with _otp_lock:
                _otp_codes.pop(body.credential.casefold(), None)
            raise APIError(502, "EMAIL_DELIVERY_FAILED", "Could not deliver the email code. Check SMTP settings.") from exc
        return OtpResponse(sent=True, delivery="email", expires_in=600)
    return OtpResponse(sent=True, delivery="demo", expires_in=600, demo_otp=settings.demo_otp)


def _verify_otp(credential: str, supplied: str) -> bool:
    settings = get_settings()
    key = credential.casefold()
    with _otp_lock:
        issued = _otp_codes.get(key)
        if issued is None:
            # Fixed code is intentionally available in local mode for recorded demos.
            return (
                settings.app_env == "local"
                and not settings.smtp_host
                and supplied == settings.demo_otp
            )
        code, expires = issued
        if datetime.now(UTC) > expires or not secrets.compare_digest(code, supplied):
            return False
        _otp_codes.pop(key, None)
        return True


@router.post("/auth/register", response_model=RegisterResponse)
def register(body: RegisterRequest, request: Request, db: Session = Depends(get_db)) -> RegisterResponse:
    """Register a new user account. Returns tokens so the user is logged in immediately."""
    settings = get_settings()
    _check_auth_rate(request)

    # Validate OTP (same demo OTP flow as login)
    if not _verify_otp(body.credential, body.otp):
        raise APIError(401, "UNAUTHORIZED", "Invalid OTP.")

    # Check for duplicate credential
    existing = db.scalars(select(User).where(User.credential == body.credential)).first()
    if existing is not None:
        raise APIError(409, "CONFLICT", "An account with this credential already exists.")
    duplicate_email = db.scalars(select(User).where(User.email == body.email.casefold())).first()
    if duplicate_email is not None:
        raise APIError(409, "CONFLICT", "An account with this email address already exists.")

    # Find or create the unit
    unit = db.scalars(select(Unit).where(Unit.name == body.unit_name)).first()
    if unit is None:
        unit = Unit(name=body.unit_name)
        db.add(unit)
        db.flush()

    # Create the user
    role = UserRole(body.role)
    if role != UserRole.PERSONNEL and settings.app_env != "local":
        raise APIError(403, "FORBIDDEN", "Privileged accounts must be provisioned by an administrator.")
    new_user = User(
        credential=body.credential,
        email=body.email.casefold(),
        display_name=body.display_name,
        rank_label=body.rank_label,
        role=role.value,
        unit_id=unit.unit_id,
        status=UserStatus.ACTIVE.value,
    )
    db.add(new_user)
    db.flush()

    # Bootstrap consent rows for the new user
    ensure_consent_rows(db, new_user.user_id)
    db.commit()
    db.refresh(new_user)

    # Issue tokens so the user is immediately signed in
    access = create_access_token(new_user.user_id, role, new_user.unit_id)
    refresh = create_refresh_token(new_user.user_id, role, new_user.unit_id)
    return RegisterResponse(
        user_id=str(new_user.user_id),
        role=role,
        access_token=access,
        refresh_token=refresh,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/auth/login", response_model=LoginResponse)
def login(body: LoginRequest, request: Request, db: Session = Depends(get_db)) -> LoginResponse:
    settings = get_settings()
    _check_auth_rate(request)
    user = db.scalars(select(User).where(User.credential == body.credential)).first()
    if user is None:
        raise APIError(401, "UNAUTHORIZED", "Invalid credentials.")
    if not _verify_otp(body.credential, body.otp):
        raise APIError(401, "UNAUTHORIZED", "Invalid OTP.")
    role = UserRole(user.role)
    access = create_access_token(user.user_id, role, user.unit_id)
    refresh = create_refresh_token(user.user_id, role, user.unit_id)
    return LoginResponse(
        access_token=access,
        refresh_token=refresh,
        role=role,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.get("/users/me")
def user_me(current: CurrentUser = Depends(get_current_user)) -> dict[str, str | None]:
    return {
        "user_id": str(current.id),
        "credential": current.user.credential,
        "email": current.user.email,
        "display_name": current.user.display_name,
        "rank_label": current.user.rank_label,
        "unit_name": current.user.unit.name,
        "role": current.role.value,
    }


@router.post("/auth/logout")
def logout(current: CurrentUser = Depends(get_current_user)) -> dict[str, str]:
    # Access tokens expire quickly; client removes its token. Stateless logout is acknowledged here.
    return {"status": "signed_out"}


@router.post("/auth/refresh", response_model=TokenResponse)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)) -> TokenResponse:
    try:
        payload = decode_token(body.refresh_token)
    except ValueError as exc:
        raise APIError(401, "UNAUTHORIZED", "Invalid refresh token.") from exc
    if payload.get("typ") != "refresh":
        raise APIError(401, "UNAUTHORIZED", "Refresh token required.")
    user = db.get(User, UUID(payload["sub"]))
    if user is None:
        raise APIError(401, "UNAUTHORIZED", "User not found.")
    access = create_access_token(user.user_id, UserRole(user.role), user.unit_id)
    return TokenResponse(access_token=access)


@router.get("/consent", response_model=list[ConsentItem])
def get_consent(
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsentItem]:
    rows = list_consent(db, current.id)
    db.commit()
    return [
        ConsentItem(
            data_type=r.data_type,
            status=r.status,  # type: ignore[arg-type]
            granted_at=r.granted_at,
            consent_id=r.consent_id,
        )
        for r in rows
    ]


@router.post("/consent", response_model=ConsentItem)
def post_consent(
    body: ConsentUpdate,
    current: CurrentUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsentItem:
    record = upsert_consent(db, current.user, body.data_type, body.status)
    db.commit()
    db.refresh(record)
    return ConsentItem(
        data_type=record.data_type,
        status=record.status,  # type: ignore[arg-type]
        granted_at=record.granted_at,
        consent_id=record.consent_id,
    )
