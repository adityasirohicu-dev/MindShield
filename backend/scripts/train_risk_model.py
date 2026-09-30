"""Train a tiny sklearn fallback model on synthetic features (Phase 2)."""

from __future__ import annotations

import os
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
os.chdir(BACKEND_ROOT)

import joblib  # noqa: E402
import numpy as np  # noqa: E402
from sklearn.ensemble import GradientBoostingClassifier  # noqa: E402

from app.core.config import get_settings  # noqa: E402
from app.modules.risk_engine.ml import FEATURE_ORDER  # noqa: E402


def main() -> None:
    rng = np.random.default_rng(42)
    n = 400
    X = rng.normal(size=(n, len(FEATURE_ORDER)))
    X[:, 0] = rng.uniform(1, 5, n)  # avg_stress
    X[:, 4] = rng.uniform(30, 80, n)  # duty hours
    y = (X[:, 0] * 8 + np.maximum(0, X[:, 4] - 48) * 0.5 + rng.normal(0, 3, n) > 28).astype(int)
    model = GradientBoostingClassifier(random_state=42)
    model.fit(X, y)
    path = get_settings().resolved_model_path
    path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, path)
    print(f"Wrote {path}")


if __name__ == "__main__":
    main()
