# MIND SHIELD — Design Document (v2)
## Based on "Mind Shield Tactical" Design Inspiration (Stitch Concept)

**Team:** SYNAPTIQ | **Problem Statement ID:** SIH26186
**Source inspiration:** `stitch_multi_page_mobile_app_concept.zip` (4 screens + design tokens)
**Version:** 2.0 — supersedes generic visual direction in the earlier Design & UX/UI doc with this concrete, implementable system.
**Status:** Draft — ready for frontend build

---

## 1. Design Language Summary

The inspiration deck defines a system called **"Mind Shield Tactical"** — a **Tactical Brutalism / Modern Telemetry** aesthetic. This replaces the earlier "calm wellness app" direction with something more distinctive and on-brand for a uniformed-forces tool: **clinical precision + instrument-panel discipline**, while still protecting the user psychologically (no alarming language, always paired with explanation).

**Core visual identity:**
- Flat, planar surfaces — **zero border-radius everywhere** (`rounded-none`)
- No shadows, no blur, no gradients — depth is created only by **borders and contrast**
- Monospace (`JetBrains Mono`) for all data/labels/telemetry, uppercase tracking
- `Space Grotesk` (or `Plus Jakarta Sans`, as implemented in the code samples) for headings
- `Inter` for body copy
- High-contrast slate/navy base with **cobalt blue** as the primary action color, **emerald** for nominal/positive states, **coral red** reserved strictly for alerts
- Every screen reinforces **"Command-Blind" / "Zero Chain-of-Command Visibility"** — privacy messaging is a first-class, persistently visible UI element, not buried in settings

This directly reinforces PRD requirement FR-1–FR-4 (consent/privacy) and the "trust problem" identified in the original problem statement: the visual language itself is the trust signal.

---

## 2. Design Tokens

### 2.1 Color System

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F8FAFC` | App base background (Slate 50) |
| `surface` / card fill | `#FFFFFF` | Cards, panels |
| `surface-container-high` / inset | `#F1F5F9` | Recessed sub-panels, table headers |
| `border-default` | `#E2E8F0` | Standard dividers |
| `border-emphasis` | `#CBD5E1` | Structural separators, input borders |
| `border-active` | `#0F172A` | Selected/active panel outline |
| `text-primary` | `#0F172A` | Headings, primary readouts |
| `text-secondary` | `#475569` | Labels, metadata |
| `text-disabled` | `#94A3B8` | Disabled/scaffolding |
| `primary` (Cobalt) | `#0284C7` | Primary buttons, active states, links |
| `primary-pressed` | `#0369A1` | Hover/press state |
| `command` (Deep Navy) | `#0F172A` | High-priority/command buttons |
| `alert` (Coral Red) | `#DC2626` | Alerts, destructive actions, critical risk |
| `alert-tint` | `#FEF2F2` | Alert background fill |
| `nominal` (Emerald) | `#059669` | Positive/low-risk states |
| `nominal-tint` | `#ECFDF5` | Nominal background fill |
| `advisory` (Amber) | `#D97706` | Moderate/watchlist states |

> **Risk-level color mapping (maps to PRD RiskAssessment.risk_level):**
> `low` → Emerald `#059669` · `moderate` → Amber `#D97706` · `elevated` → Coral (tint) `#DC2626` on `#FEF2F2` · `high` → Coral solid `#DC2626` with reinforced `3px` top border

### 2.2 Typography

| Style | Font | Size / Weight | Usage |
|---|---|---|---|
| `headline-lg` | Space Grotesk / Plus Jakarta Sans, 700 | 32px / 24px mobile | Screen-level headings |
| `headline-sm` | Space Grotesk, 600 | 18px | Card/section titles |
| `body-lg` / `body-md` / `body-sm` | Inter, 400 | 16 / 14 / 12px | Body copy, descriptions |
| `label-lg` / `label-md` / `label-sm` | JetBrains Mono, 500–600, **uppercase**, tracked | 13 / 11 / 10px | Data labels, chips, tags, telemetry readouts |

**Rule:** All `label-*` styles render uppercase with letter-spacing (0.06–0.1em) to emulate instrument-panel text. All numeric data (scores, percentages, durations) uses tabular figures (`font-variant-numeric: tabular-nums`) so digits don't shift width.

### 2.3 Spacing & Grid
- Base unit: 4px/8px matrix — no arbitrary spacing values.
- Mobile: 4-column grid, 16px gutters, 16px outer margin.
- Card internal padding: `space-md` (16px) to `space-lg` (24px).
- Fixed header (64px height, safe-area aware) + fixed bottom tab bar (safe-area aware) on every screen.

### 2.4 Shape & Elevation
- **Border-radius: 0px, everywhere** — buttons, cards, chips, inputs, modals. This is a strict rule, not a default.
- No drop shadows / blur. Depth = border weight + fill contrast only:
  - Tier 1 (card): white fill, `1px solid #E2E8F0`
  - Tier 2 (active/selected): `1px solid #0F172A` or `#0284C7`, optional `2px` left accent bar
  - Tier 3 (recessed/inset): `#F1F5F9` fill, `1px solid #CBD5E1`
  - Tier 4 (modal/drawer): white, `2px solid #0F172A`, scrim `#0F172A` at 60% opacity (no blur)
- Optional 45° chamfer clip-path corner accents are allowed **only** on primary/critical action buttons — used sparingly.

### 2.5 Core Components
- **Buttons:** Primary (solid cobalt), Command (solid navy, for high-priority actions like emergency/crisis), Secondary/Outline (white + slate border), Destructive (solid coral red). Heights: 32 / 40 / 48px. Label text is uppercase, `label-lg`.
- **Cards:** White fill, 1px border, header row divided by a bottom border with uppercase `label-md` category tag + status dot.
- **Chips/badges:** Rectangular, 0px radius, uppercase `label-sm`. Variants: Nominal (green), Alert (red), Operational (blue), Neutral (slate).
- **Inputs:** White fill, 1px slate border, 40px height, focus state = cobalt border + outer outline ring.
- **Checkboxes/radios:** Rigid 16×16px squares, sharp geometric check (no curves) — radios remain square-framed with a nested square indicator, not circular.
- **Data grids/lists:** Header row on `#F1F5F9` with 2px bottom border; zebra-striped rows; hover row = light blue tint + cobalt border.
- **Vital Status Banner:** Reusable component — high-contrast bordered banner with monospaced readouts, used for crisis lines and live status (see Support screen).
- **Corner crosshair (`+`) markers:** Decorative structural anchors at panel corners — optional per-screen detail, not required on every card.

---

## 3. Screens (from inspiration set)

The inspiration provides 4 core personnel-facing screens. Each maps directly to features defined in the PRD.

### 3.1 Home — "Personnel Readiness Home"
**Maps to:** FR-2 (trend view), consent/privacy messaging, Feature #2 (stress trend), #9 (privacy dashboard)

Layout (top → bottom):
1. Header: logo + "E2EE" badge + "Confidential & Encrypted" tagline; right side shows "Home Readiness / Command-Blind" + profile avatar
2. Identity ribbon: greeting, rank/badge ID, current shift tag + hours
3. **Zero Command Visibility** banner — persistent trust/consent reassurance with compliance badge (e.g. DPDP)
4. **Operational Readiness** card — large radial score (0–100 index), status chip (e.g. "Optimal Resilience"), plain-language explanation sub-panel
5. **Daily Check-In** CTA card (bordered, prominent) — "Takes 60s", primary button "Start Daily Check-In"
6. **Tactical Interventions** section — 2-up grid of quick tools (Breathing exercise, Peer/Counsellor link), plus stacked cards for Sleep and Operational Tempo (weekly bar strip, color-coded by day)
7. "Daily Anchor" — a calming quote/image module at the bottom
8. Fixed bottom tab bar: Home / Check-In / Analytics / Support

### 3.2 Check-In — "Daily Wellness Check-In"
**Maps to:** FR-1 (check-in submission), CheckIn data model, Feature #1

Layout: multi-step flow with a persistent progress bar ("Step 1 of 3", % complete).
1. **Mental Readiness State** — single-select card list (Energetic & Alert / Steady-Focused / Fatigued-Strained / Anxious-Overwhelmed / Exhausted), each with icon + description, selected state = cobalt border + tinted fill
2. **Duty Stress & Tension** — labeled slider (1–10, Calm → Nominal → High → Critical), current level shown as a chip
3. **Sleep & Biological Rest** — numeric stepper (hours, ± controls) + rest-quality 3-option selector (Restful / Interrupted / Poor)
4. **Operational Friction Factors** — multi-select chip group (Extended duty hours, Traumatic incident exposure, Family separation, Administrative load, None today) — this is the qualitative context signal
5. De-stigmatization reassurance strip (social proof: "Over 4,200 operators calibrated their baseline this shift")
6. **Automated Early-Warning Consent** toggle — explicit, scoped, with "revoke anytime" messaging directly inline (this is the Consent screen pattern reused inline, not just in Settings)
7. Primary CTA: "Continue to Step 2" + secondary "Quick Save & Finish Check-In" (allows partial submission)

### 3.3 Analytics — "Stress Trends & AI Insights"
**Maps to:** FR-5 (risk score + explanation), RiskAssessment + Explainability, Feature #11 (explainable risk view — personnel-facing simplified version), Feature #9 (privacy dashboard)

Layout:
1. Zero Supervisory Visibility status strip (reinforces trust at the point where "AI is analyzing me")
2. Page title + time-range selector (7 / 14 / 30 days / Duty Cycle)
3. **Predictive Strain Forecast** card — headline risk chip (e.g. "Moderate — Watchlist"), plain-language forecast paragraph
4. **AI Attribution Drivers** — this is the explainability UI: each contributing factor shown as a labeled horizontal bar with % impact and a one-line explanation (e.g. "Consecutive Duty Hours +35% impact — 3 back-to-back night shifts") — **this is the most important component to replicate precisely**, since it is the direct UI expression of the Explainability Service (Architecture doc §1.3/§2.2)
5. **Stress Load vs Recovery Trend** — dual-line chart with an annotated spike callout
6. **AI Early Suggestion** panel — clearly labeled "Advisory Only", actionable buttons (e.g. "Rest Protocol", "Log Off-Duty")
7. **Data Sources & Consent Controls** — a live list of each data source (Roster/Duty Log, Check-in Logs, Ambient/Phone Sensing) with Active/Opted-out status, plus "Manage Data Permissions & Consent" and "Instant Local Purge" actions

### 3.4 Support — "Confidential Support & Care"
**Maps to:** FR-9 (self-request counselling), Feature #6 (Counselling hub), CounsellingRequest model

Layout:
1. **Command-Blind Sanctuary** banner — reinforces zero-log policy for this specific screen (support requests are the most sensitive action in the app)
2. **Live Crisis Lifeline** — high-priority "Command" style red-bordered banner, tap-to-call, 24/7 badge — always at top, always reachable within one tap from launch
3. **Request 1-on-1 Session** — structured request form: transmission channel (Anonymous Voice / Secure Chat / Base Clinic), preferred time window, urgency triage (Routine 48h / Priority 4h) → "Confirm Encrypted Appointment"
4. **Unit Welfare Coordinator** card — named human contact with photo, role, "Request Discreet Callback" + email option (this is the human-in-the-loop trust anchor)
5. **Tactical Regulation Toolkit** — self-serve tools: breathing cycle exercise (with visual pacer), plus resource links (Post-Traumatic Incident Protocol, Family Distance Coping Playbook)

---

## 4. App Flow (Complete Navigation Map)

### 4.1 Primary Navigation (Personnel App)
Bottom tab bar, always visible on primary screens:

```
[ Home ]  [ Check-In ]  [ Analytics ]  [ Support ]
```

### 4.2 Full Flow Diagram (Personnel)

```
                              ┌─────────────────┐
                              │   App Launch     │
                              └────────┬─────────┘
                                       │
                              ┌────────▼─────────┐
                              │  Auth / Login     │
                              │  (credential+OTP) │
                              └────────┬─────────┘
                                       │
                     ┌─────────────────┼─────────────────┬──────────────────┐
                     ▼                 ▼                 ▼                  ▼
              ┌───────────┐    ┌──────────────┐  ┌───────────────┐  ┌──────────────┐
              │   HOME    │    │  CHECK-IN    │  │   ANALYTICS    │  │   SUPPORT    │
              └─────┬─────┘    └──────┬───────┘  └───────┬────────┘  └──────┬───────┘
                    │                 │                  │                  │
   ┌────────────────┼───────┐   ┌─────┴─────┐    ┌───────┴────────┐   ┌─────┴──────────────┐
   ▼                ▼       ▼   ▼           ▼     ▼                ▼   ▼        ▼            ▼
Readiness   Start Check-In  Breathing  Step 1:  Step 2:  Time-range  AI Attribution  Crisis  Request   Coordinator
 Score Card  (→ Check-In)   Exercise   Mood     Stress   Selector    Drivers detail  Lifeline Session    Callback
             tab                                 →Step 3:                                    (form)
                                                  Sleep                                          │
                                                  →Consent                                       ▼
                                                  Toggle                                    Confirmation
                                                  →Submit                                   → "My Requests"
                                                     │                                        status screen
                                                     ▼
                                            Confirmation +
                                            back to Home
                                            (score updates)
```

### 4.3 Detailed Step Flow — Daily Check-In (critical path)
```
Home → [Start Daily Check-In]
  → Step 1/3: Mental Readiness State (single-select) → [Continue]
  → Step 2/3: Duty Stress slider + Sleep hours/quality + Friction factors (multi-select) → [Continue]
  → Step 3/3: Review + Automated Early-Warning Consent toggle → [Continue to Submit]
  → Submission confirmation screen
  → Auto-redirect to Home (Operational Readiness card refreshes; "Updated just now")
  ⤷ Escape hatch at any step: [Quick Save & Finish Check-In] → partial save, exits to Home
```

### 4.4 Detailed Step Flow — Support Request (critical path)
```
Support tab → [Request 1-on-1 Session]
  → Select Transmission Channel (Anonymous Voice / Secure Chat / Base Clinic)
  → Select Preferred Window (Morning / Evening / Off-Duty)
  → Select Urgency Triage (Routine 48h / Priority 4h)
  → [Confirm Encrypted Appointment]
  → Confirmation screen: "Your request is confidential. An authorized counsellor will reach out."
  → Status visible under Support → My Requests (Requested → Assigned → In Progress → Closed)

  Parallel path (always available, 1 tap): [Call 1800-SHIELD] → native dialer, no in-app logging
```

### 4.5 Officer Dashboard Flow (not in inspiration screens — extrapolated from PRD/Architecture)
```
Officer Login (role-based)
  → Priority Follow-up Queue (sorted by risk level + recency)
    → Select case → Case Detail
        → Explainable Risk View (same "AI Attribution Drivers" component pattern as personnel Analytics, reused for officer context — aggregated/processed only, no raw logs)
        → Recommended Actions panel → [Mark Reviewed] / [Mark Actioned]
  → Counselling/Support Status Tracker (aggregate view)
  → Org-Level Trends (anonymized)
  → Audit Log (admin-only)
```

### 4.6 Cross-Cutting: Consent Flow
Consent is not a one-time settings screen — it appears at **three points**, by design:
1. Inline during Check-In Step 3 (Automated Early-Warning Consent toggle)
2. Persistently summarized on Home (Zero Command Visibility banner)
3. Fully manageable on Analytics screen (Data Sources & Consent Controls — per-source Active/Opted-out toggle + "Instant Local Purge")

---

## 5. Screen-to-Feature-to-API Traceability

| Screen | PRD Feature(s) | Key API Endpoints (from Architecture doc) |
|---|---|---|
| Home | #2 Stress trend, #9 Privacy dashboard | `GET /risk/me`, `GET /checkins/me` |
| Check-In | #1 Daily check-in, #8 Consent management | `POST /checkins`, `GET/POST /consent` |
| Analytics | #11 Explainable risk view, #9 Privacy dashboard | `GET /risk/me`, `GET /checkins/me`, `GET/POST /consent` |
| Support | #6 Counselling hub | `POST /counselling/requests`, `GET /counselling/requests/me` |
| Officer Dashboard (extrapolated) | #10–16 | `GET /risk/queue`, `GET /risk/{assessment_id}`, `POST /risk/{assessment_id}/review`, `GET /counselling/queue` |

---

## 6. Deviations & Notes for Implementation

- The inspiration's copy leans heavily into "tactical/command" language (e.g. "Operational Readiness," "Command-Blind"). This is intentional brand voice for this concept — **keep it**, but the underlying tone rule from the original UX doc still applies: never use language that sounds punitive or surveillance-like *toward* the user. "Command-Blind" and "Zero Log" phrasing actually reinforces the opposite (safety), so it's consistent.
- The four supplied screens use two slightly different font-family token sets (`Space Grotesk` in DESIGN.md vs. `Plus Jakarta Sans` in the actual code samples). **Standardize on `Plus Jakarta Sans` for headings** since that's what's implemented in code, and treat `Space Grotesk` as the DESIGN.md's aspirational reference — confirm with whoever owns brand before final build.
- Radial score gauge (Home) and dual-line trend chart (Analytics) should be built as reusable chart components — both reappear conceptually in the Officer Dashboard.
- The "AI Attribution Drivers" bar-list component is the single most reused pattern across the app (Analytics for personnel, Case Detail for officers) — build it first as a shared component.
