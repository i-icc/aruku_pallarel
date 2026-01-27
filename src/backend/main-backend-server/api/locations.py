from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

import firebase_client
from auth import current_user_id, require_auth
from domain.errors import AppError
from domain.models import LocationPoint
from infrastructure.firestore_repositories import FirestoreWalkRepository
from utils.time import ensure_utc

locations_api = Blueprint("locations_api", __name__, url_prefix="/v1")


def _walk_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreWalkRepository(db)


def _parse_timestamp(value):
    if isinstance(value, (int, float)):
        seconds = value / 1000 if value > 1_000_000_000_000 else value
        return datetime.fromtimestamp(seconds, tz=timezone.utc)
    if isinstance(value, str):
        text = value.replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(text)
        except ValueError:
            return None
    if hasattr(value, "tzinfo"):
        return value
    return None


def _parse_location_entry(entry):
    if not isinstance(entry, dict):
        return None
    timestamp = _parse_timestamp(entry.get("timestamp") or entry.get("time"))
    lat = entry.get("lat", entry.get("latitude"))
    lon = entry.get("lon", entry.get("longitude"))
    coords = entry.get("coords")
    if isinstance(coords, dict):
        lat = coords.get("latitude", coords.get("lat", lat))
        lon = coords.get("longitude", coords.get("lon", lon))
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return None
    if timestamp is None:
        return None
    return LocationPoint(
        lat=float(lat),
        lon=float(lon),
        timestamp=ensure_utc(timestamp),
    )


@locations_api.post("/locations:sync")
@require_auth
def sync_locations_handler():
    payload = request.get_json(silent=True) or {}
    user_id = payload.get("userId") or current_user_id()
    if not user_id:
        raise AppError("INVALID_ARGUMENT", "userId is required", 400)
    if user_id != current_user_id():
        raise AppError("FORBIDDEN", "userId mismatch", 403)

    walk_id = payload.get("walkId")
    if not walk_id:
        raise AppError("INVALID_ARGUMENT", "walkId is required", 400)
    repo = _walk_repo()
    if repo.get_walk(user_id, walk_id) is None:
        raise AppError("WALK_NOT_FOUND", "walk not found", 404)

    locations = payload.get("locations", [])
    if not isinstance(locations, list):
        raise AppError("INVALID_ARGUMENT", "locations must be an array", 400)

    points = []
    for entry in locations:
        parsed = _parse_location_entry(entry)
        if parsed is not None:
            points.append(parsed)

    if not points:
        return jsonify(result="ok", stored=0)

    points.sort(key=lambda item: item.timestamp)
    stored = repo.append_location_points(user_id, walk_id, points)
    return jsonify(result="ok", stored=stored)
