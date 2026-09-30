"""Optional Redis-backed job enqueue for Pilot/Scale. MVP uses FastAPI BackgroundTasks."""

from __future__ import annotations

import json
from uuid import UUID

from app.core.config import get_settings


def enqueue_risk_job(user_id: UUID) -> bool:
    """Return True if a Redis list push succeeded; callers fall back to BackgroundTasks."""
    redis_url = getattr(get_settings(), "redis_url", None) or None
    if not redis_url:
        return False
    try:
        import redis

        client = redis.Redis.from_url(redis_url)
        client.lpush("mindshield:risk-jobs", json.dumps({"user_id": str(user_id)}))
        return True
    except Exception:
        return False
