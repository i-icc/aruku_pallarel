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
    ingest_locations,
    request_suggestion,
    start_walk,
)
from utils.time import parse_rfc3339, to_rfc3339

walks_api = Blueprint("walks_api", __name__, url_prefix="/v1")

SUGGESTION_COOLDOWN_MINUTES = int(os.getenv("SUGGESTION_COOLDOWN_MINUTES", "5"))
SUGGESTION_MIN_DISTANCE_METERS = float(
    os.getenv("SUGGESTION_MIN_DISTANCE_METERS", "250")
)
LOCATION_BATCH_MAX_SIZE = int(os.getenv("LOCATION_BATCH_MAX_SIZE", "64"))


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


def _parse_location_points(payload, now):
    raw_locations = []
    locations = payload.get("locations")
    if isinstance(locations, list):
        raw_locations.extend(locations)
    location = payload.get("location")
    if isinstance(location, dict):
        raw_locations.append(location)

    points = []
    for raw in raw_locations:
        point = _parse_location_point(raw, now)
        if point is not None:
            points.append(point)
    return points


def _parse_location_point(raw, now):
    if not isinstance(raw, dict):
        return None
    coords = raw.get("coords")
    if not isinstance(coords, dict):
        coords = raw
    lat = coords.get("latitude", coords.get("lat"))
    lon = coords.get("longitude", coords.get("lon", coords.get("lng")))
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return None

    timestamp = parse_rfc3339(raw.get("timestamp"))
    if timestamp is None:
        timestamp = now
    return LocationPoint(lat=float(lat), lon=float(lon), timestamp=timestamp)


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


@walks_api.post("/walks/<walk_id>/locations:ingest")
@require_auth
def ingest_locations_handler(walk_id):
    payload = request.get_json(silent=True) or {}
    now = datetime.now(timezone.utc)
    points = _parse_location_points(payload, now)
    if not points:
        raise AppError("INVALID_ARGUMENT", "location is required", 400)

    user_id = current_user_id()
    result = ingest_locations(
        _walk_repo(),
        _request_repo(),
        _tasks_queue(),
        user_id,
        walk_id,
        points,
        now,
        cooldown_minutes=SUGGESTION_COOLDOWN_MINUTES,
        min_distance_meters=SUGGESTION_MIN_DISTANCE_METERS,
        max_batch_size=LOCATION_BATCH_MAX_SIZE,
    )

    response = {
        "result": result.result,
        "storedCount": result.stored_count,
    }
    if result.reason:
        response["reason"] = result.reason
    if result.suggestion is not None:
        suggestion_payload = {"result": result.suggestion.result}
        if result.suggestion.request_id:
            suggestion_payload["requestId"] = result.suggestion.request_id
        response["suggestion"] = suggestion_payload
    return jsonify(response)


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
