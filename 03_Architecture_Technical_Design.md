# Architecture & Technical Design Document
## MIND SHIELD — HLD, LLD & API Specification

**Team:** SYNAPTIQ | **Problem Statement ID:** SIH26186
**Version:** 1.0 (Prototype Scope) | **Status:** Draft

---

## 1. High-Level Design (HLD)

### 1.1 System Context Diagram (described)
```
[Personnel Mobile App (Flutter)] ---HTTPS/REST---> [API Gateway]
[Officer Web Dashboard (Web)]    ---HTTPS/REST---> [API Gateway]
                                                        |
                                                        v
                                          [Backend Services (FastAPI)]
                                          ├── Auth & Consent Service
                                          ├── Check-In / Wellness Service
                                          ├── Context/Duty Data Service
                                          ├── Sensor Ingestion Service (opt-in)
                                          ├── Risk Scoring / ML Service
                                          ├── Explainability Service
                                          ├── Counselling Routing Service
                                          └── Audit & Logging Service
                                                        |
                                                        v
                                          [PostgreSQL — Primary Data Store]
                                          [Object Storage — model artifacts, exports]
                                          [Optional: BLE Wearable Gateway (future)]
```

### 1.2 Architectural Style
- **Modular monolith for MVP** (FastAPI, single deployable backend with clearly separated internal modules) — chosen over microservices for hackathon/prototype speed, with clean module boundaries so it can be split into services later (Pilot/Scale phase).
- **Offline-first client** — personnel app queues check-ins locally (SQLite/local cache) and syncs when connectivity resumes.
- **Event-driven risk pipeline** — new data (check-in, context update) triggers a scoring job asynchronously rather than blocking the request.

### 1.3 Core Components

| Component | Responsibility |
|---|---|
| Personnel Mobile App | Check-ins, trend view, wellness tools, consent management, counselling requests |
| Officer Web Dashboard | Role-based risk review, case management, audit-visible actions |
| API Gateway | Auth verification, rate limiting, request routing |
| Auth & Consent Service | User identity, role-based access control (RBAC), consent state management |
| Check-In / Wellness Service | Stores and serves voluntary wellness data |
| Context/Duty Data Service | Ingests approved duty/leave/deployment data (from org systems or mock data for MVP) |
| Sensor Ingestion Service | Receives opt-in, minimized, on-device-processed sensor features |
| Risk Scoring / ML Service | Computes risk category from fused features |
| Explainability Service | Generates human-readable reasoning per prediction |
| Counselling Routing Service | Manages referral requests and status tracking |
| Audit & Logging Service | Immutable log of all sensitive-data access events |

### 1.4 Deployment View (Prototype)
- Single cloud VM or container (Docker) running FastAPI backend + PostgreSQL for hackathon demo
- Flutter app built for Android APK demo
- Officer dashboard as a responsive web app (can reuse Flutter web or a lightweight React app)
- Future: containerized services behind API Gateway (e.g., Kubernetes) for Pilot/Scale phase

### 1.5 Non-Functional Design Considerations
- **Scalability:** stateless backend services behind a load balancer; DB read replicas for dashboard queries at scale
- **Security:** TLS everywhere, AES-256 at rest, RBAC, secrets in a vault/secret manager, no plaintext PII in logs
- **Resilience:** async job queue (e.g., Celery/RQ or FastAPI background tasks for MVP) so risk scoring failures don't block check-in submission
- **Data minimization by design:** raw sensor data never persisted — only derived features cross into storage

---

## 2. Low-Level Design (LLD)

### 2.1 Data Model (Core Entities)

**User**
| Field | Type | Notes |
|---|---|---|
| user_id | UUID (PK) | Pseudonymized identifier |
| role | Enum | personnel / welfare_officer / counsellor / org_admin |
| unit_id | UUID (FK) | For org-level aggregation |
| created_at | timestamp | |
| status | Enum | active / inactive |

**ConsentRecord**
| Field | Type | Notes |
|---|---|---|
| consent_id | UUID (PK) | |
| user_id | UUID (FK) | |
| data_type | Enum | accelerometer / gyroscope / app_usage / ambient_light / speech_features / wearable |
| status | Enum | granted / revoked |
| granted_at | timestamp | |
| revoked_at | timestamp (nullable) | |

**CheckIn**
| Field | Type | Notes |
|---|---|---|
| checkin_id | UUID (PK) | |
| user_id | UUID (FK) | |
| mood_score | Int (1–5) | |
| stress_score | Int (1–5) | |
| recovery_score | Int (1–5) | |
| note | Text (nullable) | Optional, encrypted at rest |
| submitted_at | timestamp | |

**DutyContext**
| Field | Type | Notes |
|---|---|---|
| context_id | UUID (PK) | |
| user_id | UUID (FK) | |
| leave_days_recent | Int | |
| deployment_status | Enum | |
| duty_hours_weekly | Float | |
| transfer_count_recent | Int | |
| training_load | Float | |
| recorded_at | timestamp | |

**SensorFeature** *(derived only, never raw)*
| Field | Type | Notes |
|---|---|---|
| feature_id | UUID (PK) | |
| user_id | UUID (FK) | |
| feature_type | Enum | activity_level / app_usage_pattern / ambient_context / speech_tone_feature |
| value | Float / JSON | Aggregated/derived, not raw stream |
| window_start / window_end | timestamp | |

**RiskAssessment**
| Field | Type | Notes |
|---|---|---|
| assessment_id | UUID (PK) | |
| user_id | UUID (FK) | |
| risk_level | Enum | low / moderate / elevated / high |
| score | Float | |
| contributing_factors | JSON | Top-N features + weights for explainability |
| generated_at | timestamp | |
| reviewed_by | UUID (FK, nullable) | Officer who reviewed |
| review_status | Enum | pending / reviewed / actioned |

**CounsellingRequest**
| Field | Type | Notes |
|---|---|---|
| request_id | UUID (PK) | |
| user_id | UUID (FK) | |
| source | Enum | self_requested / risk_flagged |
| status | Enum | requested / assigned / in_progress / closed |
| assigned_counsellor_id | UUID (FK, nullable) | |
| created_at | timestamp | |
| updated_at | timestamp | |

**AuditLog**
| Field | Type | Notes |
|---|---|---|
| log_id | UUID (PK) | |
| actor_id | UUID (FK) | Who accessed |
| action | Text | e.g., "viewed_case", "exported_data" |
| target_user_id | UUID (FK, nullable) | Whose data was accessed |
| timestamp | timestamp | |
| reason_code | Text (nullable) | |

### 2.2 Risk Scoring Pipeline (Sequence)
1. Trigger: new CheckIn, DutyContext update, or SensorFeature batch arrives
2. `Feature Aggregator` pulls rolling-window features per user (e.g., last 14 days)
3. `Preprocessing` handles missing-data imputation, normalization
4. `Risk Model` (MVP: weighted rule-based scoring; Phase 2: trained ML classifier) outputs risk_level + score
5. `Explainability Module` computes top contributing factors (MVP: rule weights; Phase 2: SHAP values)
6. Result persisted as `RiskAssessment`; if risk_level ≥ elevated, case is pushed to officer queue
7. `Human Review Gate`: no automated outreach happens without officer/counsellor action

### 2.3 Consent Enforcement Logic (LLD detail)
- Every data ingestion endpoint checks `ConsentRecord.status == granted` for that `data_type` before accepting/storing data.
- Revoking consent triggers immediate stop of ingestion for that type; historical derived features remain per retention policy but are excluded from future scoring windows if user requests deletion.

### 2.4 Module Boundaries (for future microservice split)
- `auth-consent`, `wellness`, `context-data`, `sensor-ingestion`, `risk-engine`, `counselling`, `audit` — each designed as an isolated FastAPI router + service layer + repository layer from day one, so extraction into standalone services later is a low-risk refactor.

---

## 3. API Specification

Base URL (prototype): `https://api.mindshield.local/v1`
Auth: Bearer JWT (role embedded in claims: `personnel`, `welfare_officer`, `counsellor`, `org_admin`)

### 3.1 Auth
```
POST /auth/login
Body: { "credential": string, "otp": string }
Response: { "access_token": string, "role": string, "expires_in": int }

POST /auth/refresh
Body: { "refresh_token": string }
Response: { "access_token": string }
```

### 3.2 Consent
```
GET /consent
Response: [ { "data_type": string, "status": "granted"|"revoked", "granted_at": string } ]

POST /consent
Body: { "data_type": string, "status": "granted"|"revoked" }
Response: { "consent_id": string, "status": string }
```

### 3.3 Check-In
```
POST /checkins
Body: { "mood_score": int, "stress_score": int, "recovery_score": int, "note": string|null }
Response: { "checkin_id": string, "submitted_at": string }

GET /checkins/me?range=7d|30d|90d
Response: [ { "submitted_at": string, "mood_score": int, "stress_score": int, "recovery_score": int } ]
```

### 3.4 Sensor Features (opt-in only)
```
POST /sensors/features
Body: {
  "feature_type": "activity_level"|"app_usage_pattern"|"ambient_context"|"speech_tone_feature",
  "value": object,
  "window_start": string,
  "window_end": string
}
Response: { "feature_id": string, "accepted": bool }
Note: Request rejected with 403 if consent for that data_type is not "granted".
```

### 3.5 Duty/Context Data (org-system integration or mock ingestion for MVP)
```
POST /context/duty  (admin/system-only)
Body: {
  "user_id": string, "leave_days_recent": int, "deployment_status": string,
  "duty_hours_weekly": float, "transfer_count_recent": int, "training_load": float
}
Response: { "context_id": string }
```

### 3.6 Risk Assessment
```
GET /risk/me
Response: { "risk_level": string, "score": float, "generated_at": string }
Note: Personnel-facing endpoint may expose a simplified/no-score wellness summary rather than raw risk_level, per UX guidelines.

GET /risk/queue   (welfare_officer only)
Query: ?risk_level=elevated,high&sort=recency
Response: [ { "user_ref": string, "risk_level": string, "generated_at": string, "review_status": string } ]

GET /risk/{assessment_id}   (welfare_officer only)
Response: {
  "risk_level": string,
  "score": float,
  "contributing_factors": [ { "factor": string, "weight": float, "trend": string } ],
  "recommended_actions": [ string ]
}

POST /risk/{assessment_id}/review   (welfare_officer only)
Body: { "action_taken": string, "notes": string|null }
Response: { "review_status": "reviewed"|"actioned" }
```

### 3.7 Counselling
```
POST /counselling/requests
Body: { "source": "self_requested", "preferred_contact": string, "note": string|null }
Response: { "request_id": string, "status": "requested" }

GET /counselling/requests/me
Response: [ { "request_id": string, "status": string, "created_at": string } ]

GET /counselling/queue   (counsellor only)
Response: [ { "request_id": string, "source": string, "status": string, "created_at": string } ]

PATCH /counselling/requests/{request_id}   (counsellor only)
Body: { "status": "assigned"|"in_progress"|"closed", "notes": string|null }
Response: { "request_id": string, "status": string }
```

### 3.8 Audit (org_admin / security only)
```
GET /audit/logs?user_id=&actor_id=&from=&to=
Response: [ { "actor_id": string, "action": string, "target_user_id": string, "timestamp": string } ]
```

### 3.9 Error Format (standard across all endpoints)
```json
{
  "error": {
    "code": "CONSENT_REQUIRED",
    "message": "This action requires active consent for the requested data type.",
    "status": 403
  }
}
```

---

## 4. Tech Stack Summary

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Android-first) |
| Officer Dashboard | Web (Flutter Web or React) |
| Backend API | Python FastAPI |
| Database | PostgreSQL |
| ML/Risk Engine | Python ML stack (scikit-learn / XGBoost for Phase 2; rule-based for MVP) |
| Explainability | SHAP (Phase 2) |
| Async Jobs | FastAPI BackgroundTasks (MVP) → Celery/RQ (Pilot/Scale) |
| Auth | JWT-based, RBAC |
| Optional Hardware | BLE wearables (future phase) |

---

## 5. Security & Privacy Architecture

- **Encryption:** TLS 1.2+ in transit; AES-256 at rest for PostgreSQL (via disk-level or column-level encryption for sensitive fields like `note`).
- **RBAC:** Enforced at API Gateway and service layer — officers cannot query personnel outside their authorized unit scope; counsellors see only routing-relevant context, not raw risk feature data.
- **Data Minimization:** Raw sensor streams processed on-device; only aggregated/derived features transmitted and stored.
- **Consent Enforcement:** Server-side check on every ingestion endpoint (see §2.3).
- **Audit Trail:** Immutable append-only log for all sensitive-data access (§2.1 AuditLog entity).
- **Retention Policy:** TTL per data type (config-driven), deletion-on-request supported for wellness/sensor data where not legally required to retain.

---

## 6. Scaling Path (MVP → Pilot → Scale)

| Phase | Architecture Shape |
|---|---|
| MVP (Prototype) | Modular monolith, single DB instance, mock/synthetic duty data, rule-based risk model |
| AI Layer | Add trained ML model + explainability service; still single deployable |
| Pilot | Split risk-engine and sensor-ingestion into separate services; read replica for dashboard; real (approved/anonymized) data with privacy review |
| Scale | Full service split behind API Gateway, container orchestration (K8s), multi-unit tenancy, optional wearable gateway, continuous model monitoring/retraining pipeline |
