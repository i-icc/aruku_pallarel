from datetime import datetime, timezone

import firebase_client


def auth_header():
    return {"Authorization": "Bearer test-token"}


def test_users_requires_auth(client):
    response = client.get("/v1/users/me")

    assert response.status_code == 401
    assert response.json["error"]["code"] == "UNAUTHORIZED"


def test_users_create_and_get(client, fake_firestore, monkeypatch):
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

    create_response = client.post(
        "/v1/users",
        json={"nickname": "test-user"},
        headers=auth_header(),
    )

    assert create_response.status_code == 200
    assert create_response.json["userId"] == "user-123"
    assert create_response.json["nickname"] == "test-user"
    assert create_response.json["createdAt"]

    get_response = client.get("/v1/users/me", headers=auth_header())

    assert get_response.status_code == 200
    assert get_response.json["userId"] == "user-123"
    assert get_response.json["nickname"] == "test-user"
    assert get_response.json["email"] == "test@example.com"
    assert get_response.json["createdAt"] == "2026-01-12T00:00:00Z"
    assert get_response.json["lastLoginAt"] == "2026-01-12T00:00:00Z"
    assert get_response.json["totalWalks"] == 0
    assert get_response.json["totalDistanceKm"] == 0


def test_users_create_requires_nickname(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    response = client.post("/v1/users", json={}, headers=auth_header())

    assert response.status_code == 400
    assert response.json["error"]["code"] == "INVALID_ARGUMENT"


def test_users_update(client, fake_firestore, monkeypatch):
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

    fake_firestore._store[("users", "user-123")] = {
        "nickname": "old-name",
        "email": "test@example.com",
        "createdAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
    }

    response = client.patch(
        "/v1/users/me",
        json={"nickname": "new-name"},
        headers=auth_header(),
    )

    assert response.status_code == 200
    assert response.json["userId"] == "user-123"
    assert response.json["nickname"] == "new-name"
    assert response.json["updatedAt"].endswith("Z")

    get_response = client.get("/v1/users/me", headers=auth_header())
    assert get_response.status_code == 200
    assert get_response.json["nickname"] == "new-name"


def test_users_update_requires_nickname(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    response = client.patch("/v1/users/me", json={}, headers=auth_header())

    assert response.status_code == 400
    assert response.json["error"]["code"] == "INVALID_ARGUMENT"


def test_users_delete_removes_nested_docs(client, fake_firestore, monkeypatch):
    monkeypatch.setattr(
        firebase_client,
        "verify_id_token",
        lambda token: {"uid": "user-123"},
    )
    monkeypatch.setattr(
        firebase_client,
        "get_firestore_client",
        lambda: fake_firestore,
    )

    fake_firestore._store[("users", "user-123")] = {
        "nickname": "test-user",
        "createdAt": datetime(2026, 1, 12, tzinfo=timezone.utc),
    }
    fake_firestore._store[("users", "user-123", "walks", "walk-1")] = {
        "status": "active"
    }
    fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "locations", "batch-1")
    ] = {"points": []}
    fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "suggests", "suggest-1")
    ] = {"status": "sent"}
    fake_firestore._store[
        ("users", "user-123", "walks", "walk-1", "chat", "chat-1")
    ] = {"message": "hello"}

    response = client.delete("/v1/users/me", headers=auth_header())

    assert response.status_code == 200
    assert response.json["result"] == "ok"

    remaining = [
        key for key in fake_firestore._store.keys() if key[:2] == ("users", "user-123")
    ]
    assert remaining == []
