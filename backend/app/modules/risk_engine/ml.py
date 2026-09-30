from pathlib import Path

import joblib
import numpy as np

from app.core.config import get_settings
from app.modules.risk_engine.rules import Factor, ScoreResult, recommended_for, score_from_features
from app.core.enums import RiskLevel


FEATURE_ORDER = [
    "avg_stress",
    "stress_trend",
    "avg_recovery",
    "sleep_deficit",
    "duty_hours_weekly",
    "training_load",
    "transfer_count_recent",
    "friction_count",
    "traumatic_flag",
    "checkin_gap_days",
    "activity_load",
    "checkin_count",
]


def _vector(features: dict) -> np.ndarray:
    row = []
    for key in FEATURE_ORDER:
        val = features.get(key, 0)
        row.append(float(val))
    return np.array([row], dtype=float)


def score_user_features(features: dict) -> ScoreResult:
    settings = get_settings()
    path = settings.resolved_model_path
    if path.exists():
        try:
            model = joblib.load(path)
            x = _vector(features)
            if hasattr(model, "predict_proba"):
                proba = model.predict_proba(x)[0]
                classes = list(model.classes_)
                score = float(sum(p * (i + 1) for i, p in enumerate(proba)) / len(classes) * 100)
            else:
                pred = float(model.predict(x)[0])
                score = max(0.0, min(100.0, pred))
            shap_factors = _shap_or_fallback(model, x, features)
            level = _level(score)
            wellness = int(max(0, min(100, round(100 - score))))
            return ScoreResult(
                score=round(score, 2),
                risk_level=level,
                wellness_index=wellness,
                contributing_factors=shap_factors,
                recommended_actions=recommended_for(level),
                forecast_text="Model-assisted estimate. Advisory only — not a diagnosis.",
                model_version="sklearn-v1",
            )
        except Exception:
            return score_from_features(features)
    return score_from_features(features)


def _level(score: float) -> RiskLevel:
    if score >= 75:
        return RiskLevel.HIGH
    if score >= 55:
        return RiskLevel.ELEVATED
    if score >= 35:
        return RiskLevel.MODERATE
    return RiskLevel.LOW


def _shap_or_fallback(model, x: np.ndarray, features: dict) -> list[Factor]:
    try:
        import shap  # optional Phase 2 dependency

        explainer = shap.TreeExplainer(model)
        values = explainer.shap_values(x)
        if isinstance(values, list):
            values = values[-1]
        row = values[0]
        ranked = sorted(zip(FEATURE_ORDER, row), key=lambda t: abs(float(t[1])), reverse=True)[:3]
        mag = sum(abs(float(v)) for _, v in ranked) or 1.0
        return [
            Factor(
                factor=name,
                weight=round(abs(float(v)) / mag, 4),
                trend="up" if float(v) > 0 else "down",
                explanation=f"SHAP attribution for {name}.",
            )
            for name, v in ranked
        ]
    except Exception:
        fallback = score_from_features(features)
        return fallback.contributing_factors
