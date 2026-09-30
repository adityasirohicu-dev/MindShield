import os
from pathlib import Path

os.environ["DATABASE_URL"] = "sqlite:///" + str(Path(__file__).resolve().parent / "test_mindshield.db")
os.environ["SECRET_KEY"] = "test-secret-key-for-jwt"
os.environ["DEMO_OTP"] = "123456"
os.environ["K_ANONYMITY_MIN"] = "1"

from collections.abc import Generator  # noqa: E402

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.core.config import get_settings  # noqa: E402
from app.db.base import Base, import_models  # noqa: E402
from app.db.session import SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from scripts.seed import reset  # noqa: E402

get_settings.cache_clear()


@pytest.fixture(scope="session", autouse=True)
def _db() -> Generator[None, None, None]:
    import_models()
    reset()
    yield
    SessionLocal().close()


@pytest.fixture()
def db() -> Generator[Session, None, None]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


def login(client: TestClient, credential: str) -> str:
    res = client.post("/v1/auth/login", json={"credential": credential, "otp": "123456"})
    assert res.status_code == 200, res.text
    return res.json()["access_token"]
