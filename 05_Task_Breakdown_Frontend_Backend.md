# MIND SHIELD — Task Breakdown
## Frontend (→ Antigravity) / Backend (→ Cursor) Split for Parallel Prototype Build

**Team:** SYNAPTIQ | **Problem Statement ID:** SIH26186
**Purpose:** Split prototype work into two independent tracks that can be built in parallel, then integrated via the shared API contract (see Architecture doc §3 for full API spec).

---

## 0. How the Split Works

- **Frontend track (Antigravity):** Flutter/HTML mobile app — all 4 personnel screens + Officer dashboard, built against the design system and mock/stub API responses first, then wired to the real backend.
- **Backend track (Cursor):** FastAPI + PostgreSQL — data models, risk scoring pipeline, consent enforcement, all endpoints per the API spec.
- **Contract boundary:** The API Specification (Architecture doc §3) is the single source of truth both tracks build against. Frontend should build against mocked JSON matching that spec from day one so integration is a swap, not a rewrite.
- **Suggested order:** Both tracks start simultaneously. Frontend uses static/mock data until Backend's core endpoints (`/checkins`, `/consent`, `/risk/me`) are live, then integrates.

---

## PART A — FRONTEND TASKS (Antigravity)

### A1. Design System Setup (Foundation — do first)
- [ ] Set up global theme tokens: colors, typography (`JetBrains Mono`, `Plus Jakarta Sans`/`Space Grotesk`, `Inter`), spacing (4/8px matrix)
- [ ] Enforce global `border-radius: 0` across all components (buttons, cards, chips, inputs, modals)
- [ ] Build base component library:
  - [ ] Button variants: Primary (cobalt), Command (navy), Secondary/Outline, Destructive
  - [ ] Card (with header divider + status dot pattern)
  - [ ] Chip/Badge (Nominal / Alert / Operational / Neutral variants)
  - [ ] Text input, stepper, slider, multi-select chip group
  - [ ] Checkbox/radio (square, sharp check icon)
  - [ ] Data grid / list row (zebra striping, hover state)
  - [ ] Progress bar (multi-step indicator)
  - [ ] Modal/drawer (2px navy border, opaque scrim, no blur)
- [ ] Build shared **"AI Attribution Drivers"** bar-list component (factor name + % impact + labeled bar + one-line explanation) — reused across Analytics and Officer Case Detail
- [ ] Build shared radial score gauge component (0–100 index, SVG ring)
- [ ] Build shared dual-line trend chart component (Stress vs Recovery)
- [ ] Set up fixed header (safe-area aware, logo + E2EE badge + profile) and bottom tab bar (Home / Check-In / Analytics / Support)

### A2. Personnel App — Screens
- [ ] **Home Screen**
  - [ ] Identity ribbon (greeting, rank/badge, shift tag)
  - [ ] Zero Command Visibility / consent trust banner
  - [ ] Operational Readiness radial score card + status chip + explanation sub-panel
  - [ ] Daily Check-In CTA card
  - [ ] Tactical Interventions grid (Breathing, Peer/Counsellor quick links)
  - [ ] Sleep summary card + Operational Tempo weekly strip
  - [ ] Daily Anchor quote module
- [ ] **Check-In Screen (3-step flow)**
  - [ ] Step indicator/progress bar
  - [ ] Step 1: Mental Readiness State single-select list
  - [ ] Step 2: Duty Stress slider (1–10 with labeled zones) + Sleep hours stepper + rest-quality selector + Operational Friction Factors multi-select
  - [ ] Step 3: Review + Automated Early-Warning Consent toggle (with revoke-anytime microcopy)
  - [ ] "Quick Save & Finish Check-In" escape hatch at every step
  - [ ] Submission confirmation state
- [ ] **Analytics Screen**
  - [ ] Zero Supervisory Visibility status strip
  - [ ] Time-range selector (7/14/30 days / Duty Cycle)
  - [ ] Predictive Strain Forecast card (risk chip + forecast text)
  - [ ] AI Attribution Drivers list (reuse shared component)
  - [ ] Stress Load vs Recovery trend chart with spike annotation
  - [ ] AI Early Suggestion panel ("Advisory Only" label + action buttons)
  - [ ] Data Sources & Consent Controls list (per-source toggle + purge action)
- [ ] **Support Screen**
  - [ ] Command-Blind Sanctuary banner
  - [ ] Live Crisis Lifeline banner (tap-to-call, native dialer)
  - [ ] Request 1-on-1 Session form (channel select, time window select, urgency triage) + confirmation state
  - [ ] Unit Welfare Coordinator contact card + callback request action
  - [ ] Tactical Regulation Toolkit (breathing pacer widget + resource link cards)
  - [ ] "My Requests" status list (Requested/Assigned/In Progress/Closed)

### A3. Officer Dashboard (Web — extrapolated, no inspiration screen supplied)
- [ ] Role-based login screen
- [ ] Priority Follow-up Queue (list/table, sortable by risk level + recency, color-coded risk chips)
- [ ] Case Detail view — reuse AI Attribution Drivers component + Recommended Actions panel + Mark Reviewed/Actioned buttons
- [ ] Counselling/Support Status Tracker (aggregate list)
- [ ] Org-Level Trends view (aggregated/anonymized charts)
- [ ] Audit Log view (admin-only, filterable table)

### A4. App-Wide Concerns
- [ ] Offline-first check-in queuing (local cache, sync-on-reconnect indicator)
- [ ] Auth flow (login, token refresh, session expiry handling)
- [ ] Empty/loading/error states for every data-driven screen
- [ ] Accessibility pass: contrast check, screen-reader labels, dynamic text scaling, min 44×44px touch targets
- [ ] Mock data layer matching API response shapes exactly (Architecture doc §3), swappable for real endpoints via config flag

### A5. Integration (once backend endpoints are ready)
- [ ] Replace mock data layer with real API calls per endpoint
- [ ] Wire consent toggles to `POST /consent`, verify 403 handling when consent missing
- [ ] Wire check-in submission to `POST /checkins`, handle offline queue → sync
- [ ] Wire Analytics screen to `GET /risk/me` + `GET /checkins/me`
- [ ] Wire Support screen to `POST /counselling/requests` + `GET /counselling/requests/me`
- [ ] Wire Officer Dashboard to `GET /risk/queue`, `GET /risk/{assessment_id}`, `POST /risk/{assessment_id}/review`, `GET /counselling/queue`
- [ ] End-to-end demo run-through and bug fixing

---

## PART B — BACKEND TASKS (Cursor)

### B1. Project Setup (Foundation — do first)
- [ ] Initialize FastAPI project structure with module boundaries: `auth-consent`, `wellness`, `context-data`, `sensor-ingestion`, `risk-engine`, `counselling`, `audit` (each as router + service + repository layers, per Architecture doc §2.4)
- [ ] Set up PostgreSQL connection, migrations (e.g. Alembic)
- [ ] Set up JWT-based auth with RBAC (roles: `personnel`, `welfare_officer`, `counsellor`, `org_admin`)
- [ ] Standard error response format (Architecture doc §3.9)
- [ ] Basic request logging + audit logging middleware

### B2. Data Models (per Architecture doc §2.1)
- [ ] `User` table + role enum
- [ ] `ConsentRecord` table
- [ ] `CheckIn` table
- [ ] `DutyContext` table (mock/seed data for MVP — no real org-system integration yet)
- [ ] `SensorFeature` table (derived features only — schema ready even if sensing isn't wired to a real device yet)
- [ ] `RiskAssessment` table
- [ ] `CounsellingRequest` table
- [ ] `AuditLog` table
- [ ] Seed script: sample users (a few personnel + 1 officer + 1 counsellor + 1 admin) + mock duty-context data for demo purposes

### B3. Auth & Consent Endpoints
- [ ] `POST /auth/login`
- [ ] `POST /auth/refresh`
- [ ] `GET /consent`
- [ ] `POST /consent`
- [ ] Middleware: every ingestion endpoint checks `ConsentRecord.status == granted` before accepting data (§2.3) → returns `CONSENT_REQUIRED` 403 per error format

### B4. Check-In & Context Endpoints
- [ ] `POST /checkins`
- [ ] `GET /checkins/me?range=`
- [ ] `POST /context/duty` (admin/system-only, used to seed/update mock duty data)

### B5. Sensor Ingestion (schema/endpoint ready, real sensing optional for prototype)
- [ ] `POST /sensors/features` — accepts derived feature payloads only, enforces consent check
- [ ] Stub: reject raw-stream payloads by design (validate payload shape only matches "derived feature" schema)

### B6. Risk Scoring Engine (MVP = rule-based, not ML yet)
- [ ] Feature aggregator: pull rolling-window (e.g. 7–14 day) CheckIn + DutyContext (+ SensorFeature if present) per user
- [ ] Rule-based scoring function: weighted combination of stress score trend, sleep deficit, duty-hour load, friction factors → risk_level (low/moderate/elevated/high) + numeric score
- [ ] Explainability stub: output top 3 contributing factors with weights, in the same shape the real SHAP-based explainability service will later produce (so frontend integration doesn't change later)
- [ ] Trigger scoring as async background task on new CheckIn/DutyContext submission (FastAPI BackgroundTasks for MVP)
- [ ] `GET /risk/me` (simplified/no-raw-score personnel view per UX guidance)
- [ ] `GET /risk/queue` (welfare_officer only, filterable by risk_level, sortable by recency)
- [ ] `GET /risk/{assessment_id}` (welfare_officer only, full explainability payload)
- [ ] `POST /risk/{assessment_id}/review` (mark reviewed/actioned, writes to AuditLog)

### B7. Counselling Endpoints
- [ ] `POST /counselling/requests`
- [ ] `GET /counselling/requests/me`
- [ ] `GET /counselling/queue` (counsellor only)
- [ ] `PATCH /counselling/requests/{request_id}` (counsellor only)

### B8. Audit Endpoint
- [ ] `GET /audit/logs?user_id=&actor_id=&from=&to=` (org_admin/security only)
- [ ] Ensure every sensitive-data read (case detail view, counselling context, etc.) writes an AuditLog entry automatically

### B9. Security & Data Handling
- [ ] TLS termination config (or documented assumption for local demo)
- [ ] Encrypt sensitive fields at rest where feasible for prototype (e.g. `CheckIn.note`)
- [ ] RBAC enforcement tests: officer cannot access another unit's data; counsellor cannot see raw risk features, only routing-relevant fields
- [ ] Consent revocation immediately stops future ingestion (test this explicitly)

### B10. API Documentation & Testing
- [ ] Auto-generated OpenAPI/Swagger docs (FastAPI default) kept in sync with Architecture doc §3
- [ ] Postman/Thunder Client collection or `.http` file covering every endpoint, for frontend team to test against before full integration
- [ ] Basic unit tests for risk-scoring function (deterministic given fixed inputs, for demo reliability)
- [ ] Seed/reset script so the demo can be re-run cleanly

---

## 3. Shared Integration Checklist (Both Tracks — do together near the end)

- [ ] Confirm every frontend mock-data shape matches actual backend response shape exactly (field names, enums, nesting)
- [ ] Confirm risk_level color mapping is consistent (low/moderate/elevated/high → emerald/amber/coral variants) across both dashboard and personnel views
- [ ] Confirm consent-required error (403 `CONSENT_REQUIRED`) is handled gracefully in UI, not just logged
- [ ] Run full demo flow end-to-end: Check-in submit → risk score generate → Analytics screen updates → (if elevated) appears in Officer queue → Officer reviews → Counselling request flows through to counsellor queue
- [ ] Confirm no raw sensor/audio data appears anywhere in API responses or UI, per privacy-by-design requirement

---

## 4. Suggested Build Order (for a hackathon timeline)

| Phase | Frontend (Antigravity) | Backend (Cursor) |
|---|---|---|
| Day 1 | A1 Design system + component library | B1 Setup + B2 Data models + seed data |
| Day 2 | A2 Home + Check-In screens (mock data) | B3 Auth/Consent + B4 Check-in endpoints |
| Day 3 | A2 Analytics + Support screens (mock data) | B6 Risk scoring engine (rule-based) + B7 Counselling endpoints |
| Day 4 | A3 Officer Dashboard (mock data) + A5 begin integration | B5, B8, B9 remaining endpoints + security hardening |
| Day 5 | A5 Full integration + A4 polish/accessibility | B10 Docs/tests + bugfixes from integration |
| Final | Shared integration checklist + full demo run-through | Shared integration checklist + full demo run-through |
