from sqlalchemy.orm import Session

from app.modules.wellness.models import CheckIn


class CheckInRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: CheckIn) -> None:
        self.db.add(row)
