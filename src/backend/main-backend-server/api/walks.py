import os
from datetime import datetime, timezone
from uuid import uuid4

from flask import Blueprint, jsonify, request

import firebase_client
from auth import current_user_id, require_auth
from domain.errors import AppError
from domain.models import Location, LocationPoint
from infrastructure.firestore_repositories import (
    FirestoreSuggestionRequestRepository,
    FirestoreWalkRepository,
)
from infrastructure.tasks_queue import TasksQueueClient
from usecases.walks import (
    append_locations,
    finish_walk,
    request_suggestion,
    start_walk,
)
from utils.time import ensure_utc, to_rfc3339

walks_api = Blueprint("walks_api", __name__, url_prefix="/v1")

SUGGESTION_COOLDOWN_MINUTES = int(os.getenv("SUGGESTION_COOLDOWN_MINUTES", "5"))
SUGGESTION_MIN_DISTANCE_METERS = float(
    os.getenv("SUGGESTION_MIN_DISTANCE_METERS", "250")
)


def _walk_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreWalkRepository(db)


def _request_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreSuggestionRequestRepository(db)


def _tasks_queue():
    return TasksQueueClient()


def _parse_start_location(payload):
    location = payload.get("startLocation")
    if not isinstance(location, dict):
        return None
    lat = location.get("lat")
    lon = location.get("lon")
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return None
    return Location(lat=lat, lon=lon)


def _parse_timestamp(value):
    if isinstance(value, datetime):
        return ensure_utc(value)
    if isinstance(value, str):
        text = value.strip()
        if text.endswith("Z"):
            text = f"{text[:-1]}+00:00"
        try:
            return ensure_utc(datetime.fromisoformat(text))
        except ValueError:
            return None
    return None


def _parse_location_points(payload):
    raw_points = payload.get("points")
    if not isinstance(raw_points, list) or not raw_points:
        return None
    parsed = []
    for raw in raw_points:
        if not isinstance(raw, dict):
            return None
        lat = raw.get("lat", raw.get("latitude"))
        lon = raw.get("lon", raw.get("longitude"))
        if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
            return None
        if not _is_valid_coordinate(lat, lon):
            return None
        timestamp = _parse_timestamp(raw.get("timestamp"))
        if timestamp is None:
            return None
        parsed.append(LocationPoint(lat=lat, lon=lon, timestamp=timestamp))
    if not parsed:
        return None
    parsed.sort(key=lambda entry: entry.timestamp)
    return parsed


def _is_valid_coordinate(lat, lon):
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return False
    if not (-90 <= lat <= 90):
        return False
    if not (-180 <= lon <= 180):
        return False
    return True


@walks_api.post("/walks")
@require_auth
def start_walk_handler():
    payload = request.get_json(silent=True) or {}
    start_location = _parse_start_location(payload)
    if start_location is None:
        raise AppError("INVALID_ARGUMENT", "startLocation is required", 400)

    user_id = current_user_id()
    now = datetime.now(timezone.utc)
    walk_id = uuid4().hex

    walk = start_walk(_walk_repo(), user_id, walk_id, start_location, now)
    return jsonify(
        walkId=walk.walk_id,
        status=walk.status,
        startedAt=to_rfc3339(walk.started_at),
    )


@walks_api.post("/walks/<walk_id>:finish")
@require_auth
def finish_walk_handler(walk_id):
    user_id = current_user_id()
    now = datetime.now(timezone.utc)

    walk = finish_walk(_walk_repo(), user_id, walk_id, now)
    return jsonify(
        walkId=walk.walk_id,
        status=walk.status,
        finishedAt=to_rfc3339(walk.finished_at),
    )


@walks_api.post("/walks/<walk_id>/suggestions:request")
@require_auth
def request_suggestion_handler(walk_id):
    user_id = current_user_id()
    now = datetime.now(timezone.utc)

    result = request_suggestion(
        _walk_repo(),
        _request_repo(),
        _tasks_queue(),
        user_id,
        walk_id,
        now,
        cooldown_minutes=SUGGESTION_COOLDOWN_MINUTES,
        min_distance_meters=SUGGESTION_MIN_DISTANCE_METERS,
    )
    response = {"result": result.result}
    if result.request_id:
        response["requestId"] = result.request_id
    return jsonify(response)


@walks_api.post("/walks/<walk_id>/locations:append")
@require_auth
def append_locations_handler(walk_id):
    payload = request.get_json(silent=True) or {}
    points = _parse_location_points(payload)
    if points is None:
        raise AppError("INVALID_ARGUMENT", "points is required", 400)

    user_id = current_user_id()
    now = datetime.now(timezone.utc)

    location_ok = append_locations(_walk_repo(), user_id, walk_id, points)

    suggestion = request_suggestion(
        _walk_repo(),
        _request_repo(),
        _tasks_queue(),
        user_id,
        walk_id,
        now,
        cooldown_minutes=SUGGESTION_COOLDOWN_MINUTES,
        min_distance_meters=SUGGESTION_MIN_DISTANCE_METERS,
    )

    response = {
        "locationResult": "ok" if location_ok else "ng",
        "suggestion": {"result": suggestion.result},
    }
    if suggestion.request_id:
        response["suggestion"]["requestId"] = suggestion.request_id
    return jsonify(response)
