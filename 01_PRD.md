# Product Requirements Document (PRD)
## MIND SHIELD — AI-Based Predictive Personnel Stress and Welfare Monitoring System

**Team:** SYNAPTIQ | **Problem Statement ID:** SIH26186 | **Theme:** MedTech / BioTech / HealthTech | **Category:** Software
**Version:** 1.0 (Prototype Scope) | **Status:** Draft

---

## 1. Overview

MIND SHIELD is a software-first, privacy-by-design platform that predicts early signs of stress and burnout in uniformed personnel by fusing approved duty/work data, voluntary wellness check-ins, and optional phone-sensor signals — then routes at-risk individuals to confidential, human-led counselling support. It is explicitly an **early-warning and support-routing system**, not a diagnostic tool.

**One-line purpose:** Detect emerging personnel welfare risk earlier, explain it transparently, and connect it to real human support — without compromising privacy or trust.

---

## 2. Problem Statement

Uniformed personnel (Armed Forces, CAPFs, police, other uniformed services) face operational pressure, irregular duty, extended deployment, family separation, and exposure to traumatic incidents — all of which affect mental wellbeing. Current welfare monitoring relies on manual observation and self-reporting, which:

- Delays identification of changing welfare needs
- Is undermined by stigma around self-reporting
- Is reactive rather than preventive
- Offers no systematic, explainable way to flag risk before it becomes severe

Any technical solution must also solve a **trust problem**: welfare and biometric data is highly sensitive, and personnel need confidence the system won't be used for surveillance, punitive action, or unaccountable AI decision-making.

---

## 3. Goals & Objectives

| Goal | Metric |
|---|---|
| Detect emerging risk earlier than manual processes | Reduction in time-to-flag vs. baseline manual reporting |
| Maintain personnel trust and adoption | % opt-in rate for sensing, % active weekly check-ins |
| Keep AI explainable and human-controlled | 100% of high-risk flags reviewed by authorized human before action |
| Route personnel to real support | % of flagged/self-requested cases reaching a counsellor within SLA |
| Preserve privacy by design | Zero unauthorized data access incidents; full audit trail coverage |

---

## 4. Non-Goals (Explicitly Out of Scope)

- The AI does **not diagnose** any mental health condition.
- The system does **not** perform continuous precise GPS tracking as a core feature.
- The system does **not** record or store raw audio/conversations (only optional on-device derived speech features, if enabled).
- The system does **not** take automated punitive or career-impacting action — all significant actions require human review.
- Wearable integration and full sensor fusion are **not required for MVP/prototype** — phased in later.

---

## 5. Target Users & Personas

### Persona 1: Personnel (Primary User)
Uniformed service member using the app for private self-assessment, wellness tools, and optional confidential counselling access. Motivated by: privacy, ease of use, not wanting to be "watched."

### Persona 2: Welfare Officer / Authorized Reviewer
Reviews explainable risk indicators on a role-based dashboard, manages prioritized follow-ups, and coordinates referrals. Motivated by: actionable, trustworthy signals — not raw data dumps.

### Persona 3: Counsellor / Psychologist
Receives routed cases (via flag or self-request), provides confidential support, updates follow-up status. Motivated by: context without overexposure to sensitive raw data.

### Persona 4: Organization Admin
Views aggregated, anonymized welfare trends for planning. Motivated by: population-level insight without individual-level intrusion.

---

## 6. User Stories

- As **personnel**, I want to complete a private daily check-in, so that my stress trend is tracked without anyone judging me in real time.
- As **personnel**, I want to control exactly what sensor data is collected, so that I feel safe using the app.
- As **personnel**, I want to request confidential counselling directly, so that I can get help without going through a chain of command.
- As a **welfare officer**, I want to see *why* someone was flagged, so that I can trust and act on the alert appropriately.
- As a **welfare officer**, I want a prioritized queue, so that I address the most urgent cases first.
- As a **counsellor**, I want to see only the minimum necessary context, so that personnel privacy is respected even during support.
- As an **org admin**, I want aggregated trend views, so that I can plan preventive welfare programs.

---

## 7. Feature List (Prioritized)

### MVP (Prototype Scope)
- Personnel: check-in, stress trend view, breathing/relaxation tool, consent management screen, counselling request
- Officer: authorized login, explainable risk indicator view (rule-based or lightweight ML), basic follow-up queue
- Backend: consent/data-minimization layer, mock duty-context data ingestion, basic risk scoring, audit logging

### Phase 2
- Opt-in phone sensing (accelerometer, gyroscope, app-usage, ambient light)
- Explainability layer (e.g., SHAP-based feature attribution)
- Counselling routing engine with status tracking
- Privacy dashboard (what's collected, why)
- Aggregated org-level dashboard

### Phase 3 / Future
- Optional wearable (BLE) integration
- On-device speech-feature processing
- Multi-unit scaling, offline-first sync
- Continuous model evaluation/retraining pipeline

---

## 8. Functional Requirements

| ID | Requirement |
|---|---|
| FR-1 | System shall allow personnel to submit a private wellness check-in (mood, stress, sleep/recovery rating). |
| FR-2 | System shall display a personal stress trend graph over selectable time ranges. |
| FR-3 | System shall let users toggle opt-in sensing per data type, with a visible consent status. |
| FR-4 | System shall allow users to withdraw consent at any time; withdrawal stops future collection immediately. |
| FR-5 | System shall generate a risk score with a human-readable explanation for each prediction. |
| FR-6 | System shall restrict dashboard access to authenticated, authorized welfare-officer roles only. |
| FR-7 | System shall queue and prioritize flagged cases by risk severity and recency. |
| FR-8 | System shall block any high-risk automated action pending human review/approval. |
| FR-9 | System shall allow personnel to self-request counselling without a triggering risk flag. |
| FR-10 | System shall log all access to sensitive personnel data with timestamp, actor, and reason. |
| FR-11 | System shall never store raw audio; only derived, on-device features (if speech input enabled). |
| FR-12 | System shall aggregate/anonymize data for org-level views; no individual identification at that layer. |

---

## 9. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Risk score generation within 2s for a single user query (P95) |
| Scalability | Architecture must scale from single-unit pilot to multi-unit deployment without redesign |
| Availability | 99.5% uptime target for backend services in pilot phase |
| Offline Support | Core check-in/wellness features must work offline and sync when connectivity resumes |
| Security | End-to-end encryption in transit (TLS 1.2+), encryption at rest (AES-256) |
| Auditability | Every access to individual-level sensitive data must be logged and queryable |
| Accessibility | App UI must meet WCAG 2.1 AA for text contrast and touch target sizing |
| Compatibility | Android-first (Flutter), minimum Android 9+ |

---

## 10. Data Requirements (Summary — see Architecture doc for schema)

- **Duty/Work Context:** leave, deployment history, duty schedule, transfer frequency, training load, workload trends
- **Wellness Inputs:** mood/stress scores, sleep logs, recovery ratings, optional free text
- **Sensor Data (opt-in):** accelerometer, gyroscope, app-usage, ambient light, on-device speech features
- **Wearable Data (optional, future):** HRV, heart rate, sleep stages, step count
- **Metadata:** consent status/scope, timestamps, pseudonymized user ID, feature-importance outputs

---

## 11. AI/ML Requirements

- Model type: baseline rule-based/statistical scoring for MVP → gradient-boosted or lightweight ML model in Phase 2
- Explainability: every prediction must ship with a feature-attribution explanation (e.g., top 3 contributing factors)
- Fairness/bias check: model performance reviewed across duty roles, tenure, and units before pilot rollout
- No individual clinical diagnosis output — risk category only (e.g., Low / Moderate / Elevated / High)
- Human-in-the-loop gate before any "Elevated"/"High" flag triggers officer visibility

---

## 12. Success Metrics / KPIs

- % weekly active check-in rate
- % opt-in rate for sensing features
- Average time from risk flag to officer review
- Average time from flag/self-request to counsellor contact
- False-positive rate on risk flags (tracked via officer feedback loop)
- Zero critical privacy/security incidents

---

## 13. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Sensitive data exposure | Consent + minimum-data collection + encryption + audit logs |
| Incomplete/inconsistent operational data | Data-quality checks, missing-data handling in pipeline |
| False positives from noisy signals | Multi-indicator trend-based scoring, not single-reading triggers |
| Stigma / reluctance to self-report | Private, voluntary check-ins; no visibility to chain of command by default |
| Sensor privacy/battery concerns | Opt-in only, on-device processing where possible |
| Misuse of AI as diagnostic tool | Explicit "no diagnosis" policy; human review mandatory for action |

---

## 14. Rollout Plan

**MVP** → App + secure backend + check-in + counselling hub (mock/sample data)
**AI Layer** → Risk model + explainability + recommendations
**Pilot** → Approved/anonymized data, professional validation, privacy/safety review
**Scale** → Multi-unit deployment, optional wearables, continuous evaluation

---

## 15. Compliance & Legal Considerations

- Applicable data protection regulations (e.g., India's DPDP Act) must govern consent, storage, and retention design.
- Informed, explicit, revocable consent required for all optional data sources.
- Legal/ethical review required before any pilot involving real personnel data.
- Retention policy: sensitive raw data retained only as long as operationally necessary; define TTL per data type.

---

## 16. Open Questions / Assumptions

- Assumption: Pilot will begin with mock/synthetic data before any real personnel data is used.
- Open: Which organizational body owns final authority for "human review" sign-off?
- Open: Data retention period for wellness check-ins and sensor-derived features (needs legal input).
- Open: Escalation protocol if a user is flagged as high-risk but does not respond to outreach.

---

## 17. Stakeholders

| Role | Responsibility |
|---|---|
| Product/Team Lead | Overall scope, prioritization |
| ML Engineer | Risk model, explainability |
| Backend Engineer | API, data pipeline, security |
| Frontend/App Engineer | Personnel app, officer dashboard |
| UX Designer | Wireframes, design system |
| Domain Advisor (Welfare/Psych) | Validates counselling pathway, risk thresholds |
