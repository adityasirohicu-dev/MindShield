from sqlalchemy.orm import Session

from app.modules.auth_consent.models import ConsentRecord, User


class UserRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get(self, user_id) -> User | None:
        return self.db.get(User, user_id)


class ConsentRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: ConsentRecord) -> None:
        self.db.add(row)
