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
    finish_walk,
    record_locations,
    request_suggestion,
    start_walk,
)
from utils.time import to_rfc3339

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
@walks_api.post("/walks/<walk_id>/locations")
@require_auth
def record_locations_handler(walk_id):
    payload = request.get_json(silent=True)
    if payload is None:
        raise AppError("INVALID_ARGUMENT", "Body is required", 400)

    if isinstance(payload, dict):
        raw_points = [payload]
    elif isinstance(payload, list):
        raw_points = payload
    else:
        raise AppError("INVALID_ARGUMENT", "Invalid payload format", 400)

    points = []
    for p in raw_points:
        coords = p.get("coords")
        if not coords:
            continue
        lat = coords.get("latitude")
        lon = coords.get("longitude")
        ts_str = p.get("timestamp")
        if lat is None or lon is None or ts_str is None:
            continue

        try:
            if ts_str.endswith("Z"):
                ts_str = ts_str.replace("Z", "+00:00")
            ts = datetime.fromisoformat(ts_str)
            points.append(LocationPoint(lat=lat, lon=lon, timestamp=ts))
        except ValueError:
            continue

    if points:
        user_id = current_user_id()
        now = datetime.now(timezone.utc)
        record_locations(
            _walk_repo(),
            _request_repo(),
            _tasks_queue(),
            user_id,
            walk_id,
            points,
            now,
            cooldown_minutes=SUGGESTION_COOLDOWN_MINUTES,
            min_distance_meters=SUGGESTION_MIN_DISTANCE_METERS,
        )

    return jsonify(status="ok", count=len(points))
