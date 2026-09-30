from sqlalchemy.orm import Session

from app.modules.sensor_ingestion.models import SensorFeature


class SensorFeatureRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def add(self, row: SensorFeature) -> None:
        self.db.add(row)
