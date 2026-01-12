from datetime import datetime, timezone

import firebase_client


def auth_header():
    return {"Authorization": "Bearer test-token"}


def test_walks_requires_auth(client):
    response = client.post("/v1/walks", json={"startLocation": {"lat": 35.0, "lon": 139.0}})

    assert response.status_code == 401
    assert response.json["error"]["code"] == "UNAUTHORIZED"


def test_walks_start_success(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123", "email": "test@example.com"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    response = client.post(
        "/v1/walks",
        json={"startLocation": {"lat": 35.0, "lon": 139.0}},
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["walkId"]
    assert response.json["status"] == "active"
    assert response.json["startedAt"]

    walk_id = response.json["walkId"]
    stored = fake_firestore._store[("users", "user-123", "walks", walk_id)]
    assert stored["status"] == "active"
    assert stored["startedAt"] == datetime(2026, 1, 12, tzinfo=timezone.utc)
    assert "startLocation" in stored


def test_walks_start_rejects_duplicate_active(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123", "email": "test@example.com"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
    }

    response = client.post(
        "/v1/walks",
        json={"startLocation": {"lat": 35.0, "lon": 139.0}},
        headers=auth_header(),
    )

    assert response.status_code == 409
    assert response.json["error"]["code"] == "WALK_ALREADY_ACTIVE"


def test_walks_finish_updates_status(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123", "email": "test@example.com"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
    }

    response = client.post("/v1/walks/walk-1:finish", headers=auth_header())

    assert response.status_code == 200
    assert response.json["walkId"] == "walk-1"
    assert response.json["status"] == "finished"
    assert response.json["finishedAt"].endswith("Z")

    stored = fake_firestore._store[("users", "user-123", "walks", "walk-1")]
    assert stored["status"] == "finished"
    assert stored["finishedAt"] == datetime(2026, 1, 12, tzinfo=timezone.utc)


def test_walks_finish_requires_existing_walk(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123", "email": "test@example.com"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    response = client.post("/v1/walks/missing:finish", headers=auth_header())

    assert response.status_code == 404
    assert response.json["error"]["code"] == "WALK_NOT_FOUND"
