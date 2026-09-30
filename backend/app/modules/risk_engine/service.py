from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.enums import ConsentDataType, ReviewStatus, RiskLevel, UserRole
from app.core.errors import APIError
from app.modules.audit.service import write_audit
from app.modules.auth_consent.models import User
from app.modules.auth_consent.service import require_granted
from app.modules.risk_engine.aggregator import aggregate_user_features
from app.modules.risk_engine.ml import score_user_features
from app.modules.risk_engine.models import RiskAssessment
from app.modules.risk_engine.rules import Factor


def user_ref(user_id: UUID) -> str:
    return f"P-{str(user_id).split('-')[0].upper()}"


def persist_assessment_for_user(db: Session, user_id: UUID) -> RiskAssessment:
    features = aggregate_user_features(db, user_id)
    result = score_user_features(features)
    row = RiskAssessment(
        user_id=user_id,
        risk_level=result.risk_level.value,
        score=result.score,
        contributing_factors=[
            {
                "factor": f.factor,
                "weight": f.weight,
                "trend": f.trend,
                "explanation": f.explanation,
            }
            for f in result.contributing_factors
        ],
        recommended_actions=result.recommended_actions,
        forecast_text=result.forecast_text,
        wellness_index=result.wellness_index,
        model_version=result.model_version,
        generated_at=datetime.now(UTC),
        review_status=ReviewStatus.PENDING.value,
    )
    db.add(row)
    db.flush()
    return row


def latest_for_user(db: Session, user_id: UUID) -> RiskAssessment | None:
    return db.scalars(
        select(RiskAssessment)
        .where(RiskAssessment.user_id == user_id)
        .order_by(RiskAssessment.generated_at.desc())
        .limit(1)
    ).first()


def personnel_risk(db: Session, user: User) -> RiskAssessment:
    row = latest_for_user(db, user.user_id)
    if row is None:
        row = persist_assessment_for_user(db, user.user_id)
    return row


def officer_queue(
    db: Session,
    officer: User,
    risk_levels: list[str],
) -> list[RiskAssessment]:
    stmt = (
        select(RiskAssessment)
        .join(User, User.user_id == RiskAssessment.user_id)
        .where(User.unit_id == officer.unit_id, User.role == UserRole.PERSONNEL.value)
        .order_by(RiskAssessment.generated_at.desc())
    )
    if risk_levels:
        stmt = stmt.where(RiskAssessment.risk_level.in_(risk_levels))
    rows = list(db.scalars(stmt))
    latest: dict[UUID, RiskAssessment] = {}
    for row in rows:
        if row.user_id not in latest:
            latest[row.user_id] = row
    return list(latest.values())


def get_assessment_for_officer(db: Session, officer: User, assessment_id: UUID) -> RiskAssessment:
    row = db.get(RiskAssessment, assessment_id)
    if row is None:
        raise APIError(404, "NOT_FOUND", "Assessment not found.")
    target = db.get(User, row.user_id)
    if target is None or target.unit_id != officer.unit_id:
        raise APIError(403, "FORBIDDEN", "Officer cannot access another unit's data.")
    return row


def review_assessment(
    db: Session,
    officer: User,
    assessment_id: UUID,
    action_taken: str,
    notes: str | None,
    feedback: str | None,
) -> RiskAssessment:
    from app.core.security import encrypt_text

    row = get_assessment_for_officer(db, officer, assessment_id)
    row.reviewed_by = officer.user_id
    row.action_taken = action_taken
    row.review_notes_encrypted = encrypt_text(notes)
    row.officer_feedback = feedback
    row.review_status = (
        ReviewStatus.ACTIONED.value if action_taken else ReviewStatus.REVIEWED.value
    )
    write_audit(
        db,
        actor_id=officer.user_id,
        action="reviewed_case",
        target_user_id=row.user_id,
        reason_code=action_taken,
    )
    db.flush()
    return row
