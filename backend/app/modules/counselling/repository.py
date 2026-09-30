from sqlalchemy.orm import Session

from app.modules.counselling.models import CounsellingRequest


class CounsellingRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: CounsellingRequest) -> None:
        self.db.add(row)
