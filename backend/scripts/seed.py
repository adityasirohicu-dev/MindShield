"""Seed demo users, 14-day check-ins, duty context, and risk assessments."""

from __future__ import annotations

import os
import sys
from datetime import UTC, datetime, timedelta
from pathlib import Path
from uuid import UUID, uuid4

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
os.chdir(BACKEND_ROOT)

from sqlalchemy import delete, select  # noqa: E402

from app.core.enums import (  # noqa: E402
    ConsentDataType,
    ConsentStatus,
    CounsellingSource,
    CounsellingStatus,
    DeploymentStatus,
    ReadinessState,
    RestQuality,
    UserRole,
    UserStatus,
)
from app.db.base import import_models  # noqa: E402
from app.db.session import SessionLocal, engine  # noqa: E402
from app.db.base import Base  # noqa: E402
from app.modules.auth_consent.models import ConsentRecord, Unit, User  # noqa: E402
from app.modules.auth_consent.service import ensure_consent_rows, upsert_consent  # noqa: E402
from app.modules.context_data.models import DutyContext  # noqa: E402
from app.modules.counselling.models import CounsellingRequest  # noqa: E402
from app.modules.risk_engine.service import persist_assessment_for_user  # noqa: E402
from app.modules.wellness.mapping import normalize_checkin_scores  # noqa: E402
from app.modules.wellness.models import CheckIn  # noqa: E402

DEMO_IDS = {
    "alpha": UUID("11111111-1111-1111-1111-111111111111"),
    "bravo": UUID("22222222-2222-2222-2222-222222222222"),
    "personnel1": UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1"),
    "personnel2": UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2"),
    "personnel3": UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3"),
    "officer": UUID("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1"),
    "counsellor": UUID("cccccccc-cccc-cccc-cccc-ccccccccccc1"),
    "admin": UUID("dddddddd-dddd-dddd-dddd-ddddddddddd1"),
    "personnel_bravo": UUID("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4"),
    "officer_bravo": UUID("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2"),
}


def reset() -> None:
    import_models()
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed()


def seed() -> None:
    import_models()
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.get(User, DEMO_IDS["personnel1"]):
            print("Seed already present. Use scripts.reset_demo to rebuild.")
            return
        alpha = Unit(unit_id=DEMO_IDS["alpha"], name="Alpha Unit")
        bravo = Unit(unit_id=DEMO_IDS["bravo"], name="Bravo Unit")
        db.add_all([alpha, bravo])

        def user(key: str, cred: str, name: str, role: UserRole, unit: UUID, rank: str = "Operator") -> User:
            u = User(
                user_id=DEMO_IDS[key],
                credential=cred,
                display_name=name,
                rank_label=rank,
                role=role.value,
                unit_id=unit,
                status=UserStatus.ACTIVE.value,
            )
            db.add(u)
            return u

        p1 = user("personnel1", "personnel1", "Asha R.", UserRole.PERSONNEL, DEMO_IDS["alpha"], "Havildar")
        p2 = user("personnel2", "personnel2", "Kiran M.", UserRole.PERSONNEL, DEMO_IDS["alpha"])
        p3 = user("personnel3", "personnel3", "Dev P.", UserRole.PERSONNEL, DEMO_IDS["alpha"])
        user("officer", "officer", "Welfare Officer Nair", UserRole.WELFARE_OFFICER, DEMO_IDS["alpha"], "WO")
        user("counsellor", "counsellor", "Counsellor Mehta", UserRole.COUNSELLOR, DEMO_IDS["alpha"], "Psych")
        user("admin", "admin", "Org Admin", UserRole.ORG_ADMIN, DEMO_IDS["alpha"], "Admin")
        user("personnel_bravo", "personnel_bravo", "Bravo Operator", UserRole.PERSONNEL, DEMO_IDS["bravo"])
        user("officer_bravo", "officer_bravo", "Bravo Officer", UserRole.WELFARE_OFFICER, DEMO_IDS["bravo"], "WO")
        db.flush()

        for uid in (
            DEMO_IDS["personnel1"],
            DEMO_IDS["personnel2"],
            DEMO_IDS["personnel3"],
            DEMO_IDS["personnel_bravo"],
        ):
            ensure_consent_rows(db, uid)
            upsert_consent(db, db.get(User, uid), ConsentDataType.RISK_SCORING, ConsentStatus.GRANTED)

        now = datetime.now(UTC)
        for day in range(14):
            ts = now - timedelta(days=13 - day)
            # personnel1: worsening strain so they land on officer queue
            stress10 = min(10, 5 + day // 2)
            sleep = max(3.5, 7.2 - day * 0.2)
            readiness = (
                ReadinessState.ANXIOUS_OVERWHELMED if day > 8 else ReadinessState.FATIGUED_STRAINED
            )
            mood, stress, recovery = normalize_checkin_scores(
                mood_score=None,
                stress_score=None,
                recovery_score=None,
                readiness_state=readiness.value,
                duty_stress_10=stress10,
                sleep_hours=sleep,
                rest_quality=RestQuality.POOR.value if day > 6 else RestQuality.INTERRUPTED.value,
            )
            db.add(
                CheckIn(
                    user_id=p1.user_id,
                    mood_score=mood,
                    stress_score=stress,
                    recovery_score=recovery,
                    readiness_state=readiness.value,
                    duty_stress_10=stress10,
                    sleep_hours=sleep,
                    rest_quality=RestQuality.POOR.value if day > 6 else RestQuality.INTERRUPTED.value,
                    friction_factors=["extended_duty_hours", "family_separation"] if day > 5 else ["none_today"],
                    client_submitted_at=ts,
                    submitted_at=ts,
                )
            )
            mood2, stress2, rec2 = normalize_checkin_scores(
                mood_score=None,
                stress_score=None,
                recovery_score=None,
                readiness_state=ReadinessState.STEADY_FOCUSED.value,
                duty_stress_10=4,
                sleep_hours=7.5,
                rest_quality=RestQuality.RESTFUL.value,
            )
            db.add(
                CheckIn(
                    user_id=p2.user_id,
                    mood_score=mood2,
                    stress_score=stress2,
                    recovery_score=rec2,
                    readiness_state=ReadinessState.STEADY_FOCUSED.value,
                    duty_stress_10=4,
                    sleep_hours=7.5,
                    rest_quality=RestQuality.RESTFUL.value,
                    friction_factors=["none_today"],
                    client_submitted_at=ts,
                    submitted_at=ts,
                )
            )

        db.add_all(
            [
                DutyContext(
                    user_id=p1.user_id,
                    leave_days_recent=0,
                    deployment_status=DeploymentStatus.DEPLOYED.value,
                    duty_hours_weekly=72,
                    transfer_count_recent=2,
                    training_load=6.5,
                ),
                DutyContext(
                    user_id=p2.user_id,
                    leave_days_recent=4,
                    deployment_status=DeploymentStatus.GARRISON.value,
                    duty_hours_weekly=42,
                    transfer_count_recent=0,
                    training_load=2.0,
                ),
                DutyContext(
                    user_id=p3.user_id,
                    leave_days_recent=1,
                    deployment_status=DeploymentStatus.TRAINING.value,
                    duty_hours_weekly=50,
                    transfer_count_recent=1,
                    training_load=3.0,
                ),
            ]
        )
        db.add(
            CounsellingRequest(
                user_id=p1.user_id,
                source=CounsellingSource.SELF_REQUESTED.value,
                status=CounsellingStatus.REQUESTED.value,
                channel="secure_chat",
                urgency="priority_4h",
                time_window="Tonight 2100-2300",
                preferred_contact="secure_chat",
            )
        )
        db.flush()
        persist_assessment_for_user(db, p1.user_id)
        persist_assessment_for_user(db, p2.user_id)
        persist_assessment_for_user(db, p3.user_id)
        db.commit()
        print("Seed complete. Demo OTP=123456")
        print("Users: personnel1, personnel2, personnel3, officer, counsellor, admin, personnel_bravo, officer_bravo")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
