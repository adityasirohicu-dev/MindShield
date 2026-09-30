from sqlalchemy.orm import Session

from app.modules.risk_engine.models import RiskAssessment


class RiskAssessmentRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: RiskAssessment) -> None:
        self.db.add(row)
