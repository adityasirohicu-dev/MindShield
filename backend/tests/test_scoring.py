from app.modules.wellness.mapping import normalize_checkin_scores
from app.modules.risk_engine.rules import score_from_features
from app.core.enums import RiskLevel


def test_stitch_mapping_is_deterministic():
    mood, stress, recovery = normalize_checkin_scores(
        mood_score=None,
        stress_score=None,
        recovery_score=None,
        readiness_state="exhausted",
        duty_stress_10=10,
        sleep_hours=3.0,
        rest_quality="poor",
    )
    assert (mood, stress, recovery) == (1, 5, 1)


def test_rules_high_strain_uses_trends_not_single_reading():
    low = score_from_features(
        {
            "avg_stress": 2.0,
            "stress_trend": 0,
            "avg_recovery": 4,
            "sleep_deficit": 0,
            "duty_hours_weekly": 40,
            "training_load": 1,
            "transfer_count_recent": 0,
            "friction_count": 0,
            "traumatic_flag": False,
            "checkin_gap_days": 0,
            "activity_load": 0,
            "checkin_count": 10,
        }
    )
    high = score_from_features(
        {
            "avg_stress": 4.8,
            "stress_trend": 1.2,
            "avg_recovery": 1.5,
            "sleep_deficit": 3.5,
            "duty_hours_weekly": 72,
            "training_load": 7,
            "transfer_count_recent": 3,
            "friction_count": 3,
            "traumatic_flag": True,
            "checkin_gap_days": 5,
            "activity_load": 0,
            "checkin_count": 4,
        }
    )
    assert low.risk_level == RiskLevel.LOW
    assert high.risk_level in {RiskLevel.ELEVATED, RiskLevel.HIGH}
    assert len(high.contributing_factors) == 3
    assert high.score == score_from_features(
        {
            "avg_stress": 4.8,
            "stress_trend": 1.2,
            "avg_recovery": 1.5,
            "sleep_deficit": 3.5,
            "duty_hours_weekly": 72,
            "training_load": 7,
            "transfer_count_recent": 3,
            "friction_count": 3,
            "traumatic_flag": True,
            "checkin_gap_days": 5,
            "activity_load": 0,
            "checkin_count": 4,
        }
    ).score
