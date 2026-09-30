import logging

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.errors import APIError, api_error_handler, http_error_handler, validation_error_handler
from app.db.base import import_models
from app.middleware.request_log import RequestLogMiddleware
from app.modules.audit.router import router as audit_router
from app.modules.auth_consent.router import router as auth_router
from app.modules.context_data.router import router as context_router
from app.modules.counselling.router import router as counselling_router
from app.modules.privacy.router import org_router, privacy_router
from app.modules.risk_engine.router import router as risk_router
from app.modules.sensor_ingestion.router import router as sensor_router
from app.modules.wearables.router import router as wearable_router
from app.modules.wellness.router import router as wellness_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
import_models()
settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="MIND SHIELD API — early-warning and support-routing. Not a diagnostic tool.",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(RequestLogMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(APIError, api_error_handler)
app.add_exception_handler(HTTPException, http_error_handler)
app.add_exception_handler(RequestValidationError, validation_error_handler)

PREFIX = "/v1"
for r in (
    auth_router,
    wellness_router,
    context_router,
    sensor_router,
    risk_router,
    counselling_router,
    audit_router,
    privacy_router,
    org_router,
    wearable_router,
):
    app.include_router(r, prefix=PREFIX)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": settings.app_name, "env": settings.app_env}


@app.get("/v1/health")
def health_v1() -> dict:
    return health()
