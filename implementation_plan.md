# MIND SHIELD Frontend Implementation Plan

This document outlines the phased implementation plan for the frontend of the MIND SHIELD project, based on the provided product requirements, architectural design, and "Tactical Brutalism" design language.

## User Review Required

> [!IMPORTANT]
> **Tech Stack Confirmation**
> The architecture document mentions Flutter for the Mobile App and React/Flutter Web for the Officer Dashboard. As an AI assistant, my primary strength lies in rapidly building highly responsive, premium web applications (using React, Next.js, or Vite). 
> 
> **Recommendation**: For a fast, high-quality prototype, I recommend building the entire frontend (both Personnel App and Officer Dashboard) as a **responsive Progressive Web App (PWA) using React/Vite or Next.js**. This allows us to use a single codebase while perfectly achieving the mobile layouts for personnel and desktop layouts for officers. Please confirm if this approach is acceptable.

## Open Questions

> [!WARNING]
> **Design Assets**
> The design document refers to `stitch_multi_page_mobile_app_concept.zip` and specific icons/assets. While I can recreate the layout and aesthetic perfectly using CSS, do we have specific SVG assets (e.g., logos) that need to be imported, or should I generate placeholder/representative SVGs for the prototype?

---

## Proposed Phases

### Phase 1: Project Setup & Design System Foundation
*Focus: Establishing the "Tactical Brutalism" / Modern Telemetry aesthetic in Flutter.*

- **Project Initialization**: Setup the Flutter project structure and define core themes in `pubspec.yaml`.
- **Typography & Tokens**: Integrate `JetBrains Mono` (telemetry), `Plus Jakarta Sans` (headings), and `Inter` (body) fonts. Define the strict color palette (Cobalt, Slate, Emerald, Coral) in Dart theme files.
- **Core Component Library**:
  - Implement strict `borderRadius: BorderRadius.zero` styling globally across widgets.
  - Build Custom Button widgets (Primary, Command, Secondary, Destructive).
  - Build Custom Cards, Chips/Badges (Nominal, Alert, Operational, Neutral), and TextFormFields.
  - Build the **"AI Attribution Drivers"** shared bar-list component.
  - Build the Radial Score Gauge (using a custom painter or package) and Dual-line Trend Chart components.
- **Application Shell**: Build the custom `AppBar` (Safe-area aware, E2EE badge) and `BottomNavigationBar` for the mobile view.

### Phase 2: Personnel App - Core Flows (Mock Data)
*Focus: Implementing the primary user interaction screens using static/mock models.*

- **Home Screen**:
  - Identity ribbon and Zero Command Visibility banner.
  - Operational Readiness radial score card.
  - Tactical Interventions grid and Daily Check-In CTA.
- **Check-In Flow (3-Step)**:
  - Step 1: Mental Readiness State (single-select).
  - Step 2: Duty Stress slider, Sleep stepper, Operational Friction factors.
  - Step 3: Review and Automated Early-Warning Consent toggle.
  - Implement offline-first queuing logic (using Hive or SQLite for local storage mock).

### Phase 3: Personnel App - Analytics & Support (Mock Data)
*Focus: Implementing the complex data visualization and support routing screens.*

- **Analytics Screen**:
  - Time-range selector and Predictive Strain Forecast.
  - Integrate the "AI Attribution Drivers" component.
  - Stress Load vs. Recovery trend chart.
  - Data Sources & Consent Controls (Privacy Dashboard).
- **Support Screen**:
  - Command-Blind Sanctuary and Live Crisis Lifeline banners.
  - Request 1-on-1 Session form with urgency triage.
  - Unit Welfare Coordinator contact card and Tactical Regulation Toolkit.

### Phase 4: Officer Dashboard (Mock Data)
*Focus: Implementing the views for authorized personnel.*

- **Authentication View**: Role-based login screen.
- **Priority Follow-up Queue**: Sortable data list with color-coded risk chips.
- **Case Detail View**: Reusing the AI Attribution Drivers and adding the Recommended Actions panel.
- **Overview Analytics**: Counselling/Support Status Tracker and Org-Level Trends.

### Phase 5: Backend API Integration & Polish
*Focus: Wiring the Flutter frontend to the FastAPI backend and final testing.*

- **Auth Integration**: Wire up JWT login, HTTP interceptors, and role-based routing (e.g., using `go_router`).
- **Endpoint Wiring (using `http` or `dio` package)**: 
  - Connect `POST /checkins` and handle offline sync logic.
  - Connect `GET /POST /consent` (Handling 403 `CONSENT_REQUIRED` gracefully).
  - Connect `GET /risk/me`, `GET /risk/queue`, and `GET /risk/{assessment_id}`.
  - Connect `/counselling/requests` endpoints.
- **Accessibility & UX Pass**: Ensure contrast compliance, semantics for screen readers, and smooth micro-animations.

---

## Verification Plan

### Automated/Manual Testing
- **Visual Regression**: Verify strict adherence to the 0px border-radius and color token usage across all screens.
- **Flow Verification**: Manually step through the Check-In flow to ensure state is captured correctly across the 3 steps before submission.
- **Role-Based Access**: Verify that the Personnel view and Officer Dashboard route correctly based on mocked role tokens.
- **Error Handling**: Simulate API failures and 403 Consent errors to ensure the UI responds gracefully without breaking the user experience.
