from tests.conftest import login


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_unauthenticated_is_401(client):
    res = client.get("/v1/consent")
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "UNAUTHORIZED"


def test_login_and_consent_toggle(client):
    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    listed = client.get("/v1/consent", headers=headers)
    assert listed.status_code == 200
    accel = client.post(
        "/v1/consent",
        headers=headers,
        json={"data_type": "accelerometer", "status": "granted"},
    )
    assert accel.status_code == 200
    assert accel.json()["status"] == "granted"


def test_sensor_rejected_without_consent(client):
    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/v1/consent",
        headers=headers,
        json={"data_type": "accelerometer", "status": "revoked"},
    )
    res = client.post(
        "/v1/sensors/features",
        headers=headers,
        json={
            "feature_type": "activity_level",
            "value": {"load": 0.4},
            "window_start": "2026-09-01T00:00:00Z",
            "window_end": "2026-09-01T01:00:00Z",
        },
    )
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "CONSENT_REQUIRED"


def test_sensor_rejects_raw_stream(client):
    token = login(client, "personnel2")
    headers = {"Authorization": f"Bearer {token}"}
    client.post(
        "/v1/consent",
        headers=headers,
        json={"data_type": "accelerometer", "status": "granted"},
    )
    res = client.post(
        "/v1/sensors/features",
        headers=headers,
        json={
            "feature_type": "activity_level",
            "value": {"raw_stream": [1, 2, 3]},
            "window_start": "2026-09-01T00:00:00Z",
            "window_end": "2026-09-01T01:00:00Z",
        },
    )
    assert res.status_code == 422
