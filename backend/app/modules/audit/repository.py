from sqlalchemy.orm import Session

from app.modules.audit.models import AuditLog


class AuditRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: AuditLog) -> None:
        self.db.add(row)
