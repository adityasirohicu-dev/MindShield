from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


def import_models() -> None:
    from app.modules.audit import models as audit_models  # noqa: F401
    from app.modules.auth_consent import models as auth_models  # noqa: F401
    from app.modules.context_data import models as context_models  # noqa: F401
    from app.modules.counselling import models as counselling_models  # noqa: F401
    from app.modules.risk_engine import models as risk_models  # noqa: F401
    from app.modules.sensor_ingestion import models as sensor_models  # noqa: F401
    from app.modules.wellness import models as wellness_models  # noqa: F401
