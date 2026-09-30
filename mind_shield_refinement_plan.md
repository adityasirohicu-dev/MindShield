# Mind Shield: Comprehensive Refinement & Polish Plan

This document outlines a deep review of the current state of the Mind Shield application (both the Flutter frontend and Python FastAPI backend), cataloging missing features, UX/UI improvements, and architectural refinements required to make it a polished, bug-free, production-ready product.

---

## 1. Authentication & Identity Flow

### 🚨 Critical Missing Features
- **Sign-Out Functionality:** There is currently no way to sign out once logged in.
  - *Fix:* Add a Profile/Settings menu to the `AppBar` in both `main_screen.dart` and `officer_dashboard_screen.dart`. Hook this up to the `api.logout()` method and the `onLogout` callback to redirect the user back to the login screen.
- **Dynamic User Profile:** The Home Screen (`home_screen.dart`) currently hardcodes the identity ribbon (`OPERATOR 402`, `RANK: SGT`, `UNIT: 42`).
  - *Fix:* Fetch the actual `display_name`, `rank_label`, and `unit_name` from the backend via a new `/v1/users/me` endpoint and populate the UI dynamically.

### 🛠️ UX/UI Refinements
- **Real OTP Integration:** The current OTP flow is beautifully simulated for demos, but for production, an actual SMS (e.g., Twilio) or Email (e.g., AWS SES/SMTP) provider needs to be integrated into the backend.
- **Password vs. Passwordless:** The backend currently hardcodes the password as `"demo"` for all new sign-ups and logs them in. If the app is truly OTP-based (passwordless), the password hashing logic in the database should be entirely removed in favor of short-lived OTP tokens in Redis.
- **Error Message Formatting:** The login and sign-up screens currently force error messages to `toUpperCase()`. This feels aggressive (like shouting at the user). It should be changed to standard sentence-case.

---

## 2. Personnel Experience (Main App)

### 🚨 Critical Missing Features
- **Historical Data Visualization:** The `analytics_screen.dart` is present but needs to properly query the `/v1/checkins/me` endpoint to display a calendar heat-map or line charts showing the user's stress and readiness trends over time.
- **Check-in Persistence:** After submitting a check-in, the user receives a snackbar. However, the Home Screen should update immediately to reflect that the daily check-in is complete (hiding the "DAILY CHECK-IN" CTA until the next day).

### 🛠️ UX/UI Refinements
- **Check-in Friction:** The check-in form can feel tedious if done daily.
  - *Fix:* Break the form into a multi-step pager (one question per screen) with large, tappable emoji/icon cards instead of sliders or dropdowns. Add subtle micro-animations to make it feel rewarding.
- **Tactical Interventions:** The "Breathing" and "Grounding" intervention cards on the Home Screen currently do nothing. They should open immersive, full-screen breathing exercises (with animated expanding/contracting circles and haptic feedback).

---

## 3. Officer / Counsellor Dashboard

### 🚨 Critical Missing Features
- **Live Data Fetching:** The `officer_dashboard_screen.dart` currently relies heavily on hardcoded mock data (`_queue`, `_counsellingQueue`, `_auditLog`). 
  - *Fix:* It must be wired to the backend endpoints (`/v1/risk/queue`, `/v1/counselling/queue`, and `/v1/org/trends`).
- **Actioning Cases:** When an officer reviews a case and marks it as "actioned", this state is only updated locally in Flutter. It needs to send a `POST /v1/risk/review` request to persist the review status.

### 🛠️ UX/UI Refinements
- **Empty States:** When the queue is empty, the UI should show a reassuring "Inbox Zero" graphic (e.g., "All personnel are within nominal parameters") rather than a blank screen.
- **Filtering & Sorting:** Officers need the ability to filter the queue by specific Units, Risk Levels, or Date ranges. A filter chip row below the tab bar would greatly enhance usability.
- **Session Expiry Handling:** If an officer leaves the dashboard open for a long time and their token expires, they should be seamlessly prompted to re-authenticate without losing their place.

---

## 4. Backend & API

### 🚨 Critical Missing Features
- **Profile / "Me" Endpoint:** As mentioned above, a `GET /v1/users/me` endpoint is required to serve the user's display name, rank, unit, and role to the frontend upon successful login.
- **Data Pruning (Cron Job):** The `RETENTION_DAYS_SENSOR` rules in `.env` indicate that old data should be deleted. The `apply_retention.py` script exists but needs to be scheduled as a background task (e.g., using Celery or an OS-level Cron) to run nightly.

### 🛠️ Architectural Refinements
- **Rate Limiting:** The `/auth/login` and `/auth/register` endpoints need aggressive rate-limiting (e.g., 5 requests per minute per IP) to prevent OTP brute-forcing.
- **Validation Strictness:** Ensure Pydantic schemas reject unknown extra fields (`extra = "forbid"`) to prevent potential NoSQL-style injection or payload pollution, even though this uses SQLAlchemy.

---

## 5. Global Polish (The "Wow" Factor)

1. **Haptic Feedback:** Integrate the `flutter_vibrate` or `haptic_feedback` package. Add subtle vibrations when buttons are pressed, when the OTP completes successfully, and when a check-in is submitted.
2. **Transitions:** Currently, screen transitions are the default OS slide/fade. Implement custom `PageRouteBuilder` transitions (like a smooth fade-through or shared-axis transition) using the `animations` package for a premium feel.
3. **Typography Scaling:** Ensure that all text scales gracefully if the user has large text enabled in their OS accessibility settings. Use `FittedBox` or `Flexible` around heavily constrained text like the "E2EE" badge.
