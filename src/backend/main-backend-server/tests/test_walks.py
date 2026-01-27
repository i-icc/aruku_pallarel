from datetime import datetime, timedelta, timezone

import api.walks as walks_api
import firebase_client
from firebase_admin import firestore


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


def test_walks_suggestions_request_enqueues(client, fake_firestore, monkeypatch):
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

    calls = []

    class FakeQueue:
        def enqueue_suggestion(self, payload):
            calls.append(payload)
            return True

    monkeypatch.setattr(walks_api, "_tasks_queue", lambda: FakeQueue())

    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
        "startLocation": firestore.GeoPoint(35.0, 139.0),
    }
    fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "locations", "batch-1")
    ] = {
        "index": 1,
        "points": [
            {
                "timestamp": datetime(2026, 1, 12, tzinfo=timezone.utc),
                "geo": firestore.GeoPoint(35.003, 139.0),
            }
        ],
    }

    response = client.post(
        "/v1/walks/walk-1/suggestions:request",
        json={"requestedAt": "2026-01-12T00:00:00Z"},
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["requestId"]
    assert calls
    assert calls[0]["walkId"] == "walk-1"
    assert calls[0]["requestId"] == response.json["requestId"]
    assert (
        fake_firestore._store[("requests", response.json["requestId"])][
            "status"
        ]
        == "queued"
    )


def test_walks_suggestions_request_cooldown(client, fake_firestore, monkeypatch):
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

    called = {"count": 0}

    class FakeQueue:
        def enqueue_suggestion(self, payload):
            called["count"] += 1
            return True

    monkeypatch.setattr(walks_api, "_tasks_queue", lambda: FakeQueue())

    last_time = datetime.now(timezone.utc) - timedelta(minutes=3)
    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
    }
    fake_firestore._store[("requests", "request-1")] = {
        "requestId": "request-1",
        "userId": "user-123",
        "walkId": "walk-1",
        "requestedAt": last_time,
        "status": "done",
    }

    response = client.post(
        "/v1/walks/walk-1/suggestions:request",
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["result"] == "ng"
    assert "requestId" not in response.json
    assert called["count"] == 0


def test_walks_suggestions_request_distance_short(client, fake_firestore, monkeypatch):
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

    called = {"count": 0}

    class FakeQueue:
        def enqueue_suggestion(self, payload):
            called["count"] += 1
            return True

    monkeypatch.setattr(walks_api, "_tasks_queue", lambda: FakeQueue())

    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
        "startLocation": firestore.GeoPoint(35.0, 139.0),
    }
    fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "locations", "batch-1")
    ] = {
        "index": 1,
        "points": [
            {
                "timestamp": datetime(2026, 1, 12, tzinfo=timezone.utc),
                "geo": firestore.GeoPoint(35.0005, 139.0),
            }
        ],
    }

    response = client.post(
        "/v1/walks/walk-1/suggestions:request",
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["result"] == "ng"
    assert "requestId" not in response.json
    assert called["count"] == 0


def test_walks_locations_append_stores_and_requests(
    client, fake_firestore, monkeypatch
):
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

    calls = []

    class FakeQueue:
        def enqueue_suggestion(self, payload):
            calls.append(payload)
            return True

    monkeypatch.setattr(walks_api, "_tasks_queue", lambda: FakeQueue())

    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active",
        "startedAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
        "startLocation": firestore.GeoPoint(35.0, 139.0),
    }

    response = client.post(
        "/v1/walks/walk-1/locations:append",
        json={
            "points": [
                {
                    "timestamp": "2026-01-12T00:00:00Z",
                    "lat": 35.003,
                    "lon": 139.0,
                }
            ],
            "source": "background",
        },
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["locationResult"] == "ok"
    assert response.json["suggestion"]["result"] == "ok"
    assert response.json["suggestion"]["requestId"]
    assert calls

    stored = fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "locations", "1")
    ]
    assert stored["index"] == 1
    assert stored["count"] == 1
    assert stored["points"][0]["geo"].latitude == 35.003

    request_id = response.json["suggestion"]["requestId"]
    assert (
        fake_firestore._store[("requests", request_id)]["status"] == "queued"
    )


def test_walks_locations_append_requires_points(client, fake_firestore, monkeypatch):
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
        "startLocation": firestore.GeoPoint(35.0, 139.0),
    }

    response = client.post(
        "/v1/walks/walk-1/locations:append",
        json={},
        headers=auth_header(),
    )

    assert response.status_code == 400
    assert response.json["error"]["code"] == "INVALID_ARGUMENT"
