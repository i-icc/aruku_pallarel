from datetime import datetime, timezone

import pytest
from firebase_admin import firestore

import firebase_client
from app import app as flask_app


class FakeDocSnapshot:
    def __init__(self, data, doc_id, reference):
        self._data = data
        self.id = doc_id
        self.reference = reference

    @property
    def exists(self):
        return self._data is not None

    def to_dict(self):
        return self._data


class FakeDocRef:
    def __init__(self, store, path, now):
        self._store = store
        self._path = tuple(path)
        self._now = now

    def set(self, data, merge=False):
        resolved = {}
        for key, value in data.items():
            if value is firestore.SERVER_TIMESTAMP:
                resolved[key] = self._now
            else:
                resolved[key] = value

        if merge and self._path in self._store:
            merged = dict(self._store[self._path])
            merged.update(resolved)
            self._store[self._path] = merged
        else:
            self._store[self._path] = resolved

    def get(self):
        data = self._store.get(self._path)
        return FakeDocSnapshot(data, self._path[-1], self)

    def delete(self):
        self._store.pop(self._path, None)

    def collection(self, name):
        return FakeCollection(self._store, list(self._path) + [name], self._now)

    def collections(self):
        prefix = self._path
        collection_names = set()
        for key in self._store.keys():
            if len(key) >= len(prefix) + 2 and key[: len(prefix)] == prefix:
                collection_names.add(key[len(prefix)])
        return [
            FakeCollection(self._store, list(prefix) + [name], self._now)
            for name in sorted(collection_names)
        ]


class FakeCollection:
    def __init__(self, store, path, now):
        self._store = store
        self._path = tuple(path)
        self._now = now

    def document(self, doc_id):
        return FakeDocRef(self._store, list(self._path) + [doc_id], self._now)

    def stream(self):
        prefix = self._path
        for key, value in list(self._store.items()):
            if len(key) == len(prefix) + 1 and key[: len(prefix)] == prefix:
                doc_id = key[-1]
                ref = FakeDocRef(self._store, list(prefix) + [doc_id], self._now)
                yield FakeDocSnapshot(value, doc_id, ref)


class FakeFirestoreClient:
    def __init__(self, now):
        self._store = {}
        self._now = now

    def collection(self, name):
        return FakeCollection(self._store, [name], self._now)


@pytest.fixture

def client():
    flask_app.config.update(TESTING=True)
    with flask_app.test_client() as test_client:
        yield test_client


@pytest.fixture

def fake_firestore():
    return FakeFirestoreClient(datetime(2026, 1, 12, tzinfo=timezone.utc))


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
