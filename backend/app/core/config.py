from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BACKEND_ROOT / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "MIND SHIELD"
    app_env: str = "local"
    secret_key: str = "dev-secret-change-me"
    fernet_key: str = ""
    database_url: str = "sqlite:///./mindshield.db"
    demo_otp: str = "123456"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = ""
    smtp_starttls: bool = True
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    cors_origins: str = "*"
    retention_days_checkin: int = 365
    retention_days_sensor: int = 90
    retention_days_audit: int = 730
    k_anonymity_min: int = 5
    model_path: str = "models/artifacts/risk_model.joblib"

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def resolved_model_path(self) -> Path:
        path = Path(self.model_path)
        if not path.is_absolute():
            return BACKEND_ROOT / path
        return path


@lru_cache
def get_settings() -> Settings:
    return Settings()
