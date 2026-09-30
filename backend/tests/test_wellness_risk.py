from tests.conftest import login


def test_checkin_and_risk_me(client):
    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    res = client.post(
        "/v1/checkins",
        headers=headers,
        json={
            "readiness_state": "steady_focused",
            "duty_stress_10": 4,
            "sleep_hours": 7.5,
            "rest_quality": "restful",
            "friction_factors": ["none_today"],
            "note": "offline-sync-test",
            "client_submitted_at": "2026-09-22T04:00:00Z",
            "early_warning_consent": True,
        },
    )
    assert res.status_code == 200, res.text
    again = client.post(
        "/v1/checkins",
        headers=headers,
        json={
            "readiness_state": "steady_focused",
            "duty_stress_10": 4,
            "sleep_hours": 7.5,
            "rest_quality": "restful",
            "client_submitted_at": "2026-09-22T04:00:00Z",
        },
    )
    assert again.json()["checkin_id"] == res.json()["checkin_id"]
    mine = client.get("/v1/checkins/me?range=14d", headers=headers)
    assert mine.status_code == 200
    assert len(mine.json()) >= 1
    risk = client.get("/v1/risk/me", headers=headers)
    assert risk.status_code == 200
    body = risk.json()
    assert "wellness_index" in body
    assert "score" not in body
    assert body["risk_level"] in {"low", "moderate", "elevated", "high"}


def test_officer_queue_and_cross_unit_forbidden(client):
    officer = login(client, "officer")
    headers = {"Authorization": f"Bearer {officer}"}
    queue = client.get("/v1/risk/queue?risk_level=elevated,high,moderate,low", headers=headers)
    assert queue.status_code == 200
    assert len(queue.json()) >= 1
    assessment_id = queue.json()[0]["assessment_id"]
    detail = client.get(f"/v1/risk/{assessment_id}", headers=headers)
    assert detail.status_code == 200
    assert "score" in detail.json()
    review = client.post(
        f"/v1/risk/{assessment_id}/review",
        headers=headers,
        json={"action_taken": "offer_counselling", "notes": "reviewed"},
    )
    assert review.status_code == 200

    other = login(client, "officer_bravo")
    other_h = {"Authorization": f"Bearer {other}"}
    denied = client.get(f"/v1/risk/{assessment_id}", headers=other_h)
    assert denied.status_code == 403

    counsellor = login(client, "counsellor")
    c_h = {"Authorization": f"Bearer {counsellor}"}
    blocked = client.get(f"/v1/risk/{assessment_id}", headers=c_h)
    assert blocked.status_code == 403
