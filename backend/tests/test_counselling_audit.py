from tests.conftest import login


def test_counselling_flow(client):
    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    created = client.post(
        "/v1/counselling/requests",
        headers=headers,
        json={
            "source": "self_requested",
            "channel": "secure_chat",
            "urgency": "routine_48h",
            "time_window": "Tomorrow AM",
            "preferred_contact": "secure_chat",
        },
    )
    assert created.status_code == 200, created.text
    request_id = created.json()["request_id"]
    mine = client.get("/v1/counselling/requests/me", headers=headers)
    assert any(r["request_id"] == request_id for r in mine.json())

    counsellor = login(client, "counsellor")
    ch = {"Authorization": f"Bearer {counsellor}"}
    queue = client.get("/v1/counselling/queue", headers=ch)
    assert queue.status_code == 200
    item = next(r for r in queue.json() if r["request_id"] == request_id)
    assert "contributing_factors" not in item
    patched = client.patch(
        f"/v1/counselling/requests/{request_id}",
        headers=ch,
        json={"status": "assigned", "notes": "slot reserved"},
    )
    assert patched.status_code == 200
    assert patched.json()["status"] == "assigned"


def test_audit_admin_only(client):
    officer = login(client, "officer")
    denied = client.get("/v1/audit/logs", headers={"Authorization": f"Bearer {officer}"})
    assert denied.status_code == 403
    admin = login(client, "admin")
    logs = client.get("/v1/audit/logs", headers={"Authorization": f"Bearer {admin}"})
    assert logs.status_code == 200
    assert isinstance(logs.json(), list)


def test_org_trends_and_privacy(client):
    admin = login(client, "admin")
    trends = client.get("/v1/org/trends", headers={"Authorization": f"Bearer {admin}"})
    assert trends.status_code == 200
    assert "user_id" not in trends.text
    body = trends.json()
    assert "buckets" in body

    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    sources = client.get("/v1/privacy/sources", headers=headers)
    assert sources.status_code == 200
    purge = client.post("/v1/privacy/purge", headers=headers, json={})
    assert purge.status_code == 200
    assert purge.json()["excluded_from_future_scoring"] is True
