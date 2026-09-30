# Design & UX/UI Document
## MIND SHIELD — Visual & Interaction Blueprint

**Team:** SYNAPTIQ | **Problem Statement ID:** SIH26186
**Version:** 1.0 (Prototype Scope) | **Status:** Draft

---

## 1. Design Principles

1. **Privacy-visible, not privacy-hidden** — the app should constantly and calmly reassure the user about what's tracked and why.
2. **Calm, not clinical** — visual tone should reduce anxiety, not feel like a surveillance tool.
3. **Human-in-the-loop, always** — dashboards emphasize "review" and "support," never "control" or "surveillance."
4. **Explain, don't just alert** — every risk indicator shown to an officer must carry its reasoning.
5. **Low cognitive load** — personnel using this app may be fatigued/stressed; interactions must be minimal-friction.
6. **Accessibility first** — legible type, strong contrast, large touch targets (personnel may use the app in varied field conditions).

---

## 2. Information Architecture

### 2.1 Personnel App — Navigation Map
```
Home (Dashboard)
├── Daily Check-In
├── Stress Trend View
├── Wellness Tools
│   ├── Guided Breathing/Relaxation
│   └── Sleep/Recovery Guidance
├── Recommendations
├── Counselling & Support Hub
│   ├── Request Session
│   └── My Requests / Status
├── Privacy & Consent
│   ├── Consent Manager (toggle per data type)
│   └── Privacy Dashboard (what's collected)
└── Settings / Profile
```

### 2.2 Welfare Officer Dashboard — Navigation Map
```
Login (Role-based Auth)
├── Overview / Home
│   ├── Priority Follow-up Queue
│   └── Alert Summary (counts by risk level)
├── Case View (per flagged individual — access-controlled)
│   ├── Explainable Risk Indicator
│   ├── Trend History (aggregated, not raw)
│   └── Recommended Intervention
├── Counselling/Support Status Tracker
├── Org-Level Trends (aggregated/anonymized)
└── Audit Log (access history)
```

---

## 3. Key User Flows

### Flow 1: Daily Check-In (Personnel)
1. Open app → Home shows "Check in today" prompt
2. Tap → 3-step micro-survey (mood, stress, sleep/recovery) — slider or emoji-scale inputs
3. Optional free-text note (skippable)
4. Submit → confirmation + optional immediate tip (e.g., breathing exercise suggestion)
5. Data reflected in personal Stress Trend View

### Flow 2: Enabling Opt-In Sensing
1. Personnel navigates to Privacy & Consent
2. Sees list of sensor types, each OFF by default, each with plain-language description of what it captures and why
3. Toggles ON individually → confirmation modal explains data handling (on-device processing, no raw storage)
4. Can revoke anytime from same screen

### Flow 3: Requesting Counselling
1. Personnel taps Counselling & Support Hub
2. Chooses "Request Session" (self-initiated, no flag required)
3. Optional context note (skippable) + preferred contact method
4. Confirmation: "Your request is confidential. An authorized counsellor will reach out."
5. Status visible only to requester under "My Requests"

### Flow 4: Officer Reviewing a Flag
1. Officer logs in (role-based auth) → sees Priority Follow-up Queue sorted by risk/recency
2. Selects a case → sees Explainable Risk Indicator (e.g., "Elevated — driven by: irregular sleep pattern, reduced check-in frequency, extended duty stretch")
3. Sees recommended intervention options (e.g., "Suggest wellness check / Offer counselling referral")
4. Marks action taken → logged in audit trail
5. No raw sensor data or free-text notes shown — only processed, minimum-necessary indicators

---

## 4. Wireframe Descriptions (Prototype-Level)

> For a hackathon prototype, low-fidelity wireframes are sufficient. Below are described layouts a designer/frontend dev can build directly from.

### 4.1 Personnel — Home Screen
- Top: Greeting + today's check-in status (done/not done)
- Middle: Stress trend mini-chart (last 7 days)
- Card row: Quick actions — [Check In] [Breathing Exercise] [Counselling]
- Bottom nav: Home | Trends | Support | Privacy | Profile

### 4.2 Personnel — Check-In Screen
- Step indicator (1/3, 2/3, 3/3)
- Large touch-friendly slider or 5-point emoji scale per question
- "Skip" allowed only on free-text, not on core 3 questions
- Primary CTA button, full-width, bottom-anchored

### 4.3 Personnel — Consent Manager
- List view, one row per data type (e.g., "Accelerometer & Motion")
- Each row: icon, name, one-line description, toggle switch, "Learn more" expandable
- Persistent banner: "You can change this anytime."

### 4.4 Officer — Priority Queue
- Table/list view: Name/ID (role-permission dependent), Risk Level badge (color-coded), Last updated, Days since flag
- Sort/filter by risk level, unit, recency
- Row tap → Case Detail view

### 4.5 Officer — Case Detail (Explainable Risk View)
- Header: Risk Level badge + short summary sentence
- "Why this flag" panel: top 3 contributing factors, plain-language, each with a small trend sparkline
- "Recommended Actions" panel: 2–3 suggested next steps (button per action)
- No raw personal notes/sensor streams — aggregated indicators only

---

## 5. Visual Design System

### 5.1 Color Palette — Light Gradient Refresh
| Role | Color | Usage |
|---|---|---|
| Action teal | `#267C78` | Primary actions and active states |
| Deep navy | `#1B2A4A` | Headings and high-emphasis content |
| Indigo accent | `#596BC2` | Secondary accents and selected indicators |
| Background | `#F6F8FC` | Calm app canvas |
| Surface | `#FFFFFF` | Cards, forms, and readable content areas |
| Brand gradient | `#E2F6F1` → `#E8ECFF` | Featured sections and page ambience |
| Risk – Low | `#2E7D32` | Pair with a “Low” or “Nominal” label |
| Risk – Moderate | `#865100` | Pair with a “Moderate” label |
| Risk – Elevated | `#B7473D` | Pair with an “Elevated” label |
| Risk – High | `#B0231C` | Pair with a “High” label |
| Text Primary | `#182433` | Main content |
| Text Secondary | `#5D6C7C` | Supporting copy and metadata |

Gradients are limited to a few feature surfaces. Keep text and forms on solid light surfaces for contrast. Status must never be communicated by color alone.

### 5.2 Typography
- Primary typeface: system-default sans-serif (e.g., Inter / Roboto) for performance and native feel
- Headings: Semi-bold, 20–28px
- Body: Regular, 14–16px
- Minimum touch target: 44x44px

### 5.3 Iconography
- Rounded, minimal-line icon set (not sharp/tactical imagery — avoid militarized visual metaphors that increase stress)
- Consistent icon language for privacy states (unlocked/locked, on/off)

### 5.4 Components (Reusable)
- Buttons: Primary (filled), Secondary (outline), Destructive (for consent revoke)
- Cards: Rounded corners (8–12px), soft shadow, no accent-stripe borders
- Badges: Pill-shaped, color-coded by risk level
- Toggles: iOS/Material-style switch with clear on/off state
- Sliders: Large thumb target, labeled endpoints
- Modals: Used for consent explanations and confirmation actions

---

## 6. Accessibility & Inclusivity Guidelines

- WCAG 2.1 AA minimum contrast ratio (4.5:1 for body text)
- All interactive elements reachable via screen reader with descriptive labels
- No color-only signaling for risk levels — pair color with text label/icon
- Support for dynamic text scaling
- Language: plain, non-clinical, non-alarming wording throughout (e.g., "Let's check in" not "Report your symptoms")

---

## 7. Tone & Content Guidelines

- Never use alarming language ("Warning," "Danger") in personnel-facing UI — use supportive framing ("We noticed a change — want to talk to someone?")
- Officer-facing UI can be more clinical/direct but must always pair a flag with an explanation, never a bare score
- Avoid militarized or surveillance-coded visual metaphors (e.g., no red "tracking" pins, no CCTV-style icons)

---

## 8. Prototype Build Priorities (for Frontend Dev)

1. Personnel: Home, Check-In flow, Stress Trend View, Consent Manager
2. Officer: Login, Priority Queue, Case Detail (Explainable Risk View)
3. Shared: Design tokens (colors, type, spacing) implemented first so both flows stay visually consistent
4. Defer: Wearable UI, advanced analytics charts, multi-language support (post-MVP)
