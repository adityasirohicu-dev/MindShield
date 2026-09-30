# Mind Shield: Project Memory & Context Document

This document serves as a persistent memory bank for the Mind Shield project, capturing its purpose, architecture, and a chronological log of changes and decisions made during development.

---

## 1. Project Overview
**Name:** Mind Shield (SYNAPTIQ · SIH26186)  
**Purpose:** A personal wellness and health analytics platform designed for operational personnel (military, law enforcement, first responders). It provides early-warning risk scoring, secure check-ins, and support routing while strictly adhering to data privacy (Zero Command Visibility, DPDP Compliant).

**Architecture:**
- **Frontend:** Flutter (Web/Mobile capabilities). Contains distinct flows for standard members (`main_screen.dart`, `home_screen.dart`) and administrative users (`officer_dashboard_screen.dart`).
- **Backend:** Python / FastAPI with SQLAlchemy ORM. Uses a robust modular structure (`app/modules/`) handling auth, risk engine, wellness check-ins, counselling, and audit logs.

---

## 2. Conversation & Development History

### Phase 1: Environment Setup & Execution
- **Task:** The user requested to "turn on backend". 
- **Action:** Investigated the Python backend structure and successfully launched the FastAPI server using `uvicorn` in the `.venv` on `localhost:8000`.
- **Task:** The user later requested to "close the backend".
- **Action:** Safely killed the background server task.
- **Task:** The user requested to load the frontend.
- **Action:** Attempted to run the Flutter web server. Encountered a port conflict on default port `8080`. Successfully started the server on `localhost:3000`. Later handled a request to restart by locating and killing an orphaned process on port `3000` via Windows `netstat` and `taskkill`.

### Phase 2: Authentication & Sign-Up Flow
- **Task:** User identified that there was no way to sign up (neither in the app nor the backend API).
- **Action:** Confirmed that the system relied entirely on a `seed.py` script for demo users. 
- **Implementation:** 
  1. **Backend:** Created `RegisterRequest` and `RegisterResponse` schemas. Built a `POST /v1/auth/register` endpoint in the `auth_consent` router that validates credentials, creates a unit/user, bootstraps consent records, and returns JWT tokens for immediate login.
  2. **Frontend:** Added a `register()` method to `mind_shield_api.dart`. Created a brand new `signup_screen.dart` matching the glass-morphism aesthetic of the login screen. Added routing toggles in `main.dart` to switch between Login and Sign-Up.

### Phase 3: OTP Simulation Polish
- **Task:** User questioned the "Passcode" field, noting we didn't collect a phone number or email to actually send an OTP.
- **Action:** Explained that the current OTP was a hardcoded demo value (`123456`). Agreed with the user to adopt "Option 2": Simulating a realistic OTP flow without integrating a paid SMS/Email API yet.
- **Implementation:** Rewrote both `signup_screen.dart` and `login_screen.dart`. Added Email / Service ID fields, a "Send OTP" button with a simulated 1.2-second network delay, a green success snackbar, a 30-second resend countdown, and logic that prevents submitting the form until the OTP is "sent".

### Phase 4: Comprehensive Deep Review
- **Task:** User requested a deep dive study of the app to list refinements needed to make it a "perfect no bug product", specifically noting the lack of a sign-out button.
- **Action:** Conducted a thorough review of the Flutter widget tree and FastAPI routers. 
- **Implementation:** Generated a detailed markdown report (`mind_shield_refinement_plan.md`) highlighting:
  1. **Missing Authentication UI:** The `onLogout` callback exists but is missing from the AppBars.
  2. **Dynamic Data Needs:** The Home screen uses hardcoded strings (`OPERATOR 402`) instead of fetching a profile.
  3. **Mock Data Wiring:** The Officer Dashboard uses hardcoded lists instead of hitting the API.
  4. **UX Friction:** Identified areas for improvement, such as check-in form gamification and interactive tactical interventions.

---

## 3. Current State & Next Steps
As of the latest session, the app has a beautiful, simulated passwordless auth flow, but lacks the ability to sign out, and relies heavily on mock data in the UI. 

**Immediate Priorities Recommended:**
1. Add a Profile/Settings menu to the AppBars to expose the Sign-Out button.
2. Build a `GET /v1/users/me` endpoint to hydrate the UI with real user names and ranks.
3. Wire the Officer Dashboard tabs to the live FastAPI endpoints.
