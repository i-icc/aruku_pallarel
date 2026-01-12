from datetime import datetime, timezone

import pytest

from app import app as flask_app
from fake_firestore import FakeFirestoreClient


@pytest.fixture
def client():
    flask_app.config.update(TESTING=True)
    with flask_app.test_client() as test_client:
        yield test_client


@pytest.fixture
def fake_firestore():
    return FakeFirestoreClient(datetime(2026, 1, 12, tzinfo=timezone.utc))
