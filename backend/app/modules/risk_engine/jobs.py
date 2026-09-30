from uuid import UUID

from fastapi import BackgroundTasks
from sqlalchemy.orm import Session

from app.db.session import SessionLocal
from app.modules.risk_engine.service import persist_assessment_for_user


def run_scoring_job(user_id: UUID) -> None:
    db: Session = SessionLocal()
    try:
        persist_assessment_for_user(db, user_id)
        db.commit()
    finally:
        db.close()


def enqueue_scoring(background: BackgroundTasks, user_id: UUID) -> None:
    from app.modules.risk_engine.queue import enqueue_risk_job

    if enqueue_risk_job(user_id):
        return
    background.add_task(run_scoring_job, user_id)
