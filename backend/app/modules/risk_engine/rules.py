from __future__ import annotations

from dataclasses import dataclass, field

from app.core.enums import RiskLevel


@dataclass
class Factor:
    factor: str
    weight: float
    trend: str
    explanation: str


@dataclass
class ScoreResult:
    score: float
    risk_level: RiskLevel
    wellness_index: int
    contributing_factors: list[Factor]
    recommended_actions: list[str]
    forecast_text: str
    model_version: str = "rules-v1"


def _level_from_score(score: float) -> RiskLevel:
    if score >= 75:
        return RiskLevel.HIGH
    if score >= 55:
        return RiskLevel.ELEVATED
    if score >= 35:
        return RiskLevel.MODERATE
    return RiskLevel.LOW


def _chip_text(level: RiskLevel) -> str:
    mapping = {
        RiskLevel.LOW: "Optimal Resilience",
        RiskLevel.MODERATE: "Moderate — Watchlist",
        RiskLevel.ELEVATED: "Elevated strain — review advised",
        RiskLevel.HIGH: "High strain — human review required",
    }
    return mapping[level]


def recommended_for(level: RiskLevel) -> list[str]:
    if level == RiskLevel.HIGH:
        return [
            "Offer confidential counselling referral",
            "Reduce consecutive duty load if operationally possible",
            "Schedule welfare officer follow-up within 24h",
        ]
    if level == RiskLevel.ELEVATED:
        return [
            "Suggest wellness check-in conversation",
            "Offer counselling referral",
            "Monitor sleep recovery over next 72h",
        ]
    if level == RiskLevel.MODERATE:
        return ["Encourage rest protocol", "Keep check-in cadence daily"]
    return ["Maintain current support access", "No command action required"]


def score_from_features(features: dict) -> ScoreResult:
    """Deterministic weighted rules. Single-reading spikes are damped by trends."""
    avg_stress = float(features.get("avg_stress", 3))
    stress_trend = float(features.get("stress_trend", 0))
    avg_recovery = float(features.get("avg_recovery", 3))
    sleep_deficit = float(features.get("sleep_deficit", 0))
    duty_hours = float(features.get("duty_hours_weekly", 40))
    training_load = float(features.get("training_load", 0))
    transfers = float(features.get("transfer_count_recent", 0))
    friction_count = float(features.get("friction_count", 0))
    checkin_gap_days = float(features.get("checkin_gap_days", 0))
    activity_load = float(features.get("activity_load", 0))
    traumatic = bool(features.get("traumatic_flag", False))

    parts: list[Factor] = []

    stress_w = max(0.0, (avg_stress - 2) * 10 + max(0.0, stress_trend) * 12)
    parts.append(
        Factor(
            "stress_load_trend",
            round(stress_w, 2),
            "up" if stress_trend > 0.15 else "stable" if stress_trend > -0.15 else "down",
            "Sustained duty stress across the rolling window, not a single reading.",
        )
    )

    sleep_w = sleep_deficit * 8 + max(0.0, 3 - avg_recovery) * 10
    parts.append(
        Factor(
            "sleep_recovery_deficit",
            round(sleep_w, 2),
            "up" if sleep_deficit > 1 else "stable",
            "Sleep hours and rest quality below recovery baseline.",
        )
    )

    duty_over = max(0.0, duty_hours - 48)
    duty_w = duty_over * 0.9 + training_load * 4 + transfers * 3
    parts.append(
        Factor(
            "operational_tempo",
            round(duty_w, 2),
            "up" if duty_hours > 50 else "stable",
            "Weekly duty hours, training load, and recent transfers.",
        )
    )

    friction_w = friction_count * 6 + (18 if traumatic else 0)
    parts.append(
        Factor(
            "operational_friction",
            round(friction_w, 2),
            "up" if friction_count else "stable",
            "Reported friction factors such as family separation or incident exposure.",
        )
    )

    cadence_w = min(20.0, checkin_gap_days * 3)
    parts.append(
        Factor(
            "checkin_frequency",
            round(cadence_w, 2),
            "down" if checkin_gap_days > 3 else "stable",
            "Reduced check-in cadence versus the expected daily baseline.",
        )
    )

    if activity_load:
        parts.append(
            Factor(
                "opt_in_activity_load",
                round(min(12.0, activity_load * 8), 2),
                "up",
                "Derived on-device activity feature (consent-gated).",
            )
        )

    raw = sum(p.weight for p in parts)
    score = max(0.0, min(100.0, raw))
    level = _level_from_score(score)
    top = sorted(parts, key=lambda p: p.weight, reverse=True)[:3]
    total = sum(p.weight for p in top) or 1.0
    normalized = [
        Factor(
            factor=p.factor,
            weight=round(p.weight / total, 4),
            trend=p.trend,
            explanation=p.explanation,
        )
        for p in top
    ]
    wellness = int(max(0, min(100, round(100 - score))))
    forecast = (
        f"{_chip_text(level)}. Advisory only — this is not a diagnosis. "
        "Human review is required before any support outreach."
    )
    return ScoreResult(
        score=round(score, 2),
        risk_level=level,
        wellness_index=wellness,
        contributing_factors=normalized,
        recommended_actions=recommended_for(level),
        forecast_text=forecast,
    )
