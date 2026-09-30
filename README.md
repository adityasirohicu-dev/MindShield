# Mind Shield

Mind Shield is an AI-powered stress and welfare monitoring system for uniformed forces. It analyzes voluntary wellness inputs, duty context and optional sensor signals to identify emerging stress and fatigue patterns. It provides explainable risk insights, personalized wellness support and confidential counselling while ensuring privacy.

Privacy-first FastAPI backend for early welfare-risk warning and confidential support routing. It does **not** diagnose mental health conditions and never takes automated punitive action.

## Quick start

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
copy .env.example .env
```

Local demo uses SQLite if `DATABASE_URL` is unset. For Postgres:

```bash
docker compose up db -d
```

For a local SQLite demo, upgrade and seed before starting the API:

```bash
alembic upgrade head
python -m scripts.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Set `DATABASE_URL=postgresql+psycopg2://mindshield:mindshield@localhost:5432/mindshield` in `.env`, then:

```bash
alembic upgrade head
python -m scripts.seed
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Health: `GET http://localhost:8000/health`
- OpenAPI: `http://localhost:8000/docs`
- Client collection: [api.http](backend/api.http)

All-in-one: `docker compose up --build` from `backend/`.

## Deploying a live app

The GitHub repository stores the source code; it does not run the API. A live deployment needs a host for the FastAPI backend, a persistent PostgreSQL database, HTTPS, and an email SMTP provider for real OTP delivery. The Flutter app can then be built for web or Android with the hosted API URL:

```bash
cd mind_shield
flutter build web --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/v1
```

Set the backend environment variables on the hosting provider (never in this repository): `APP_ENV=production`, a unique random `SECRET_KEY`, `DATABASE_URL`, `CORS_ORIGINS`, and the `SMTP_*` values documented in [backend/.env.example](backend/.env.example). Run `alembic upgrade head` as a release step. Configure CORS to allow the deployed web origin. The local fixed OTP `123456` is for presentations only; production OTPs are delivered by email. Configure any Flutter signing credentials in the host's secret store when producing a signed Android release.

Before publishing, confirm the hosting provider and web domain so the API URL, CORS allowlist, database, and email delivery can be configured together. Keep `.env` files, database files, SMTP credentials, signing keys, and tokens out of Git. Use `.env.example` only as a template.

## Demo login

No password is used. Every seeded user uses the demo OTP `123456`.

| credential | role |
|---|---|
| personnel1 | personnel (elevated demo case) |
| personnel2 | personnel |
| personnel3 | personnel |
| officer | welfare_officer (Alpha unit) |
| counsellor | counsellor |
| admin | org_admin |
| personnel_bravo / officer_bravo | other unit (RBAC tests) |

Reset demo data: `python -m scripts.reset_demo`

## OTP delivery

The presentation build uses the fixed demo code `123456` (shown in the app after requesting a code). For real email delivery, configure `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`, and `SMTP_STARTTLS` in `backend/.env`. User accounts need a unique email address; email codes expire after 10 minutes. No SMS vendor or extra package is required. Run `alembic upgrade head` from `backend/` after updating an existing database to add the email field.

Nightly retention can be scheduled on Windows without installing a scheduler: run `powershell -ExecutionPolicy Bypass -File scripts/register_retention_task.ps1` from `backend/`. The task applies the configured check-in, sensor, and audit-log retention periods.

## Contract

REST under `/v1` matches Architecture §3, plus additive Stitch fields on check-in and counselling. Error envelope:

```json
{ "error": { "code": "CONSENT_REQUIRED", "message": "...", "status": 403 } }
```

TLS: local HTTP. Terminate TLS at a reverse proxy for any shared demo. SMTP-backed email OTP is available when configured; external identity providers remain a future integration.

## Tests

```bash
cd backend
pytest -q
```

## Phase 2 / 3 extras

- `GET /v1/privacy/sources`, `POST /v1/privacy/purge`, `DELETE /v1/privacy/me`
- `GET /v1/org/trends` (k-anonymity; no user ids)
- `POST /v1/wearables/features` (derived metrics, wearable consent)
- Optional sklearn model: `python -m scripts.train_risk_model` then scoring uses it with SHAP if `shap` is installed, else rule weights
- Retention TTL job: `python -m scripts.apply_retention`
- Kubernetes starter: [deploy/k8s/mind-shield.yaml](backend/deploy/k8s/mind-shield.yaml)
- Redis job queue: set `REDIS_URL` and `docker compose --profile jobs up redis`

## Flutter app

```bash
cd mind_shield
flutter pub get
flutter run
```

The app connects to the backend at `http://127.0.0.1:8000/v1` on desktop and web, and `http://10.0.2.2:8000/v1` on the Android emulator. Override the URL with `--dart-define=API_BASE_URL=https://your-api.example/v1` when launching. Start the backend first and use the seeded demo credentials from above.



## Flutter UI design

For the app palette, gradients, spacing, typography, shared components, and live-update workflow, see the [MIND SHIELD UI Design Guide](mind_shield/DESIGN_GUIDE.md).
