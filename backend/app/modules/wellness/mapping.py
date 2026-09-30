from app.core.enums import ReadinessState, RestQuality


READINESS_TO_MOOD = {
    ReadinessState.ENERGETIC_ALERT: 5,
    ReadinessState.STEADY_FOCUSED: 4,
    ReadinessState.FATIGUED_STRAINED: 3,
    ReadinessState.ANXIOUS_OVERWHELMED: 2,
    ReadinessState.EXHAUSTED: 1,
}


def duty_stress_to_score(duty_stress_10: int | None, fallback: int | None = None) -> int:
    if duty_stress_10 is not None:
        return max(1, min(5, (duty_stress_10 + 1) // 2))
    if fallback is not None:
        return fallback
    return 3


def recovery_from_rest(sleep_hours: float | None, rest_quality: RestQuality | str | None, fallback: int | None = None) -> int:
    if sleep_hours is None and rest_quality is None:
        return fallback if fallback is not None else 3
    hours = sleep_hours if sleep_hours is not None else 7.0
    quality = RestQuality(rest_quality) if rest_quality else RestQuality.INTERRUPTED
    if hours >= 7 and quality == RestQuality.RESTFUL:
        return 5
    if hours >= 6 and quality != RestQuality.POOR:
        return 4
    if hours >= 5:
        return 3
    if hours >= 4:
        return 2
    return 1


def normalize_checkin_scores(
    *,
    mood_score: int | None,
    stress_score: int | None,
    recovery_score: int | None,
    readiness_state: str | None,
    duty_stress_10: int | None,
    sleep_hours: float | None,
    rest_quality: str | None,
) -> tuple[int, int, int]:
    mood = mood_score
    if mood is None and readiness_state:
        mood = READINESS_TO_MOOD.get(ReadinessState(readiness_state), 3)
    if mood is None:
        mood = 3
    stress = stress_score if stress_score is not None else duty_stress_to_score(duty_stress_10)
    recovery = recovery_score if recovery_score is not None else recovery_from_rest(sleep_hours, rest_quality)
    return max(1, min(5, mood)), max(1, min(5, stress)), max(1, min(5, recovery))
