from sqlalchemy.orm import Session

from app.modules.context_data.models import DutyContext


class DutyContextRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: DutyContext) -> None:
        self.db.add(row)
