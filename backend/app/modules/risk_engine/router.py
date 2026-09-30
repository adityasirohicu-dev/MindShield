from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import CurrentUser, optional_reason, require_roles
from app.core.enums import ReviewStatus, RiskLevel, UserRole
from app.core.errors import APIError
from app.db.session import get_db
from app.modules.audit.service import write_audit
from app.modules.auth_consent.schemas import (
    FactorOut,
    RiskDetailOut,
    RiskMeOut,
    RiskQueueItem,
    RiskReviewIn,
    RiskReviewOut,
)
from app.modules.risk_engine.service import (
    get_assessment_for_officer,
    latest_for_user,
    officer_queue,
    personnel_risk,
    review_assessment,
    user_ref,
)

router = APIRouter(tags=["risk"])

CHIP = {
    RiskLevel.LOW: "Optimal Resilience",
    RiskLevel.MODERATE: "Moderate — Watchlist",
    RiskLevel.ELEVATED: "Elevated strain",
    RiskLevel.HIGH: "High strain",
}


@router.get("/risk/me", response_model=RiskMeOut)
def risk_me(
    current: CurrentUser = Depends(require_roles(UserRole.PERSONNEL)),
    db: Session = Depends(get_db),
) -> RiskMeOut:
    row = personnel_risk(db, current.user)
    db.commit()
    level = RiskLevel(row.risk_level)
    factors = [FactorOut(**f) if isinstance(f, dict) else f for f in (row.contributing_factors or [])]
    return RiskMeOut(
        risk_level=level,
        wellness_index=row.wellness_index,
        generated_at=row.generated_at,
        forecast_text=row.forecast_text,
        contributing_factors=factors,
        status_chip=CHIP[level],
    )


@router.get("/risk/queue", response_model=list[RiskQueueItem])
def risk_queue(
    risk_level: str | None = Query(default="elevated,high"),
    sort: str = Query(default="recency"),
    current: CurrentUser = Depends(require_roles(UserRole.WELFARE_OFFICER, UserRole.COUNSELLOR, UserRole.ORG_ADMIN)),
    db: Session = Depends(get_db),
    reason: str | None = Depends(optional_reason),
) -> list[RiskQueueItem]:
    levels = [p.strip() for p in (risk_level or "").split(",") if p.strip()]
    write_audit(
        db,
        actor_id=current.id,
        action="viewed_queue",
        reason_code=reason,
    )
    db.commit()
    rows = officer_queue(db, current.user, levels)
    if sort == "recency":
        rows.sort(key=lambda r: r.generated_at, reverse=True)
    elif sort == "risk":
        severity = {"high": 3, "elevated": 2, "moderate": 1, "low": 0}
        rows.sort(key=lambda r: (severity.get(r.risk_level, -1), r.generated_at), reverse=True)
    return [
        RiskQueueItem(
            assessment_id=r.assessment_id,
            user_ref=user_ref(r.user_id),
            risk_level=RiskLevel(r.risk_level),
            generated_at=r.generated_at,
            review_status=ReviewStatus(r.review_status),
        )
        for r in rows
    ]


@router.get("/risk/{assessment_id}", response_model=RiskDetailOut)
def risk_detail(
    assessment_id: UUID,
    current: CurrentUser = Depends(require_roles(UserRole.WELFARE_OFFICER, UserRole.COUNSELLOR, UserRole.ORG_ADMIN)),
    db: Session = Depends(get_db),
    reason: str | None = Depends(optional_reason),
) -> RiskDetailOut:
    row = get_assessment_for_officer(db, current.user, assessment_id)
    write_audit(
        db,
        actor_id=current.id,
        action="viewed_case",
        target_user_id=row.user_id,
        reason_code=reason or "case_review",
    )
    db.commit()
    factors = [FactorOut(**f) for f in (row.contributing_factors or [])]
    return RiskDetailOut(
        assessment_id=row.assessment_id,
        risk_level=RiskLevel(row.risk_level),
        score=row.score,
        contributing_factors=factors,
        recommended_actions=row.recommended_actions or [],
        generated_at=row.generated_at,
        review_status=ReviewStatus(row.review_status),
        user_ref=user_ref(row.user_id),
    )


@router.post("/risk/{assessment_id}/review", response_model=RiskReviewOut)
def risk_review(
    assessment_id: UUID,
    body: RiskReviewIn,
    current: CurrentUser = Depends(require_roles(UserRole.WELFARE_OFFICER)),
    db: Session = Depends(get_db),
) -> RiskReviewOut:
    row = review_assessment(db, current.user, assessment_id, body.action_taken, body.notes, body.feedback)
    db.commit()
    return RiskReviewOut(review_status=ReviewStatus(row.review_status))
