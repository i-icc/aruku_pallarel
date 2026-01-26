import time
from uuid import uuid4

from flask import Blueprint, current_app, jsonify, request

from firebase_client import get_firestore_client
from jobs.adk_client import AdkClient
from jobs.candidate_selector import select_candidate
from jobs.firestore_repositories import (
    FirestoreChatRepository,
    FirestoreSuggestionRequestRepository,
    FirestoreSuggestRepository,
    FirestoreUserRepository,
    FirestoreWalkRepository,
)
from jobs.fcm_client import FcmClient
from jobs.location_models import LocationPoint
from jobs.osm_client import OsmClient

jobs_api = Blueprint("jobs_api", __name__, url_prefix="/jobs")


def _request_repo():
    db = get_firestore_client()
    return FirestoreSuggestionRequestRepository(db)


def _walk_repo():
    db = get_firestore_client()
    return FirestoreWalkRepository(db)


def _user_repo():
    db = get_firestore_client()
    return FirestoreUserRepository(db)


def _chat_repo():
    db = get_firestore_client()
    return FirestoreChatRepository(db)


def _suggest_repo():
    db = get_firestore_client()
    return FirestoreSuggestRepository(db)


def _osm_client():
    return OsmClient()


def _adk_client():
    return AdkClient()


def _fcm_client():
    return FcmClient()


@jobs_api.post("/suggestions")
def run_suggestion_job():
    payload = request.get_json(silent=True) or {}
    request_id = payload.get("requestId")
    if not request_id:
        return jsonify(error="requestId is required"), 400

    request_repo = _request_repo()
    request_data = request_repo.get_request(request_id)
    if request_data is None:
        return jsonify(error="request_not_found"), 404

    status = request_data.get("status")
    if status != "queued":
        return jsonify(status="ignored", requestId=request_id, requestStatus=status)

    user_id = request_data.get("userId")
    walk_id = request_data.get("walkId")
    if not user_id or not walk_id:
        request_repo.update_status(request_id, "failed", error="missing_context")
        return jsonify(status="failed", requestId=request_id, error="missing_context")

    request_repo.update_status(request_id, "running")

    walk_repo = _walk_repo()
    walk_data = walk_repo.get_walk(user_id, walk_id)
    if not walk_data:
        request_repo.update_status(request_id, "failed", error="walk_not_found")
        return jsonify(status="failed", requestId=request_id, error="walk_not_found")

    start_coords = _extract_lat_lon(walk_data.get("startLocation"))
    if not start_coords:
        request_repo.update_status(request_id, "failed", error="no_start_location")
        return jsonify(status="failed", requestId=request_id, error="no_start_location")

    locations = walk_repo.get_location_points(user_id, walk_id)
    if not locations:
        request_repo.update_status(request_id, "failed", error="no_locations")
        return jsonify(status="failed", requestId=request_id, error="no_locations")

    current = locations[-1]
    start = LocationPoint(
        lat=start_coords[0],
        lon=start_coords[1],
        timestamp=locations[0].timestamp,
    )

    try:
        candidate = select_candidate(
            start=start,
            current=current,
            polyline=locations,
            osm_client=_osm_client(),
        )
    except RuntimeError as exc:
        request_repo.update_status(request_id, "failed", error="osm_failed")
        return jsonify(
            status="failed", requestId=request_id, error="osm_failed", detail=str(exc)
        )

    if candidate is None:
        request_repo.update_status(request_id, "failed", error="candidate_exhausted")
        return jsonify(status="failed", requestId=request_id, error="candidate_exhausted")

    try:
        message = _adk_client().generate_message(
            candidate.snapped.lat,
            candidate.snapped.lon,
            user_id=user_id,
            session_id=walk_id,
        )
    except RuntimeError as exc:
        request_repo.update_status(request_id, "failed", error="adk_failed")
        return jsonify(
            status="failed", requestId=request_id, error="adk_failed", detail=str(exc)
        )

    suggest_id = _new_suggest_id()
    message_id = _new_chat_id()
    maps_url = _google_maps_url(candidate.snapped.lat, candidate.snapped.lon)

    _chat_repo().create_message(
        user_id=user_id,
        walk_id=walk_id,
        chat_id=message_id,
        message=message,
        url=maps_url,
        suggest_id=suggest_id,
    )
    _suggest_repo().create_suggest(
        user_id=user_id,
        walk_id=walk_id,
        suggest_id=suggest_id,
        message_id=message_id,
        lat=candidate.snapped.lat,
        lon=candidate.snapped.lon,
    )
    request_repo.update_status(
        request_id, "done", suggest_id=suggest_id, message_id=message_id
    )

    fcm_status = _send_fcm_notification(
        user_id=user_id,
        walk_id=walk_id,
        suggest_id=suggest_id,
        message_id=message_id,
        message=message,
        lat=candidate.snapped.lat,
        lon=candidate.snapped.lon,
    )

    response_payload = {
        "status": "done",
        "requestId": request_id,
        "suggestId": suggest_id,
        "messageId": message_id,
        "message": message,
        "candidateLat": candidate.candidate.lat,
        "candidateLon": candidate.candidate.lon,
        "snappedLat": candidate.snapped.lat,
        "snappedLon": candidate.snapped.lon,
        "attempts": candidate.attempts,
    }
    if fcm_status:
        response_payload["fcmStatus"] = fcm_status
    return jsonify(response_payload)


def _extract_lat_lon(value):
    if value is None:
        return None
    if hasattr(value, "latitude") and hasattr(value, "longitude"):
        return value.latitude, value.longitude
    if isinstance(value, dict):
        lat = value.get("lat", value.get("latitude"))
        lon = value.get("lon", value.get("longitude"))
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            return lat, lon
    return None


def _new_suggest_id() -> str:
    return uuid4().hex


def _new_chat_id() -> str:
    return f"{int(time.time() * 1000)}-{uuid4().hex[:8]}"


def _google_maps_url(lat: float, lon: float) -> str:
    lat_d, lat_m, lat_s, lat_dir = _to_dms(lat, "N", "S")
    lon_d, lon_m, lon_s, lon_dir = _to_dms(lon, "E", "W")
    return (
        "https://www.google.com/maps?q="
        f"{lat_d}+{lat_m}+{lat_s:.2f}+{lat_dir}+"
        f"{lon_d}+{lon_m}+{lon_s:.2f}+{lon_dir}"
    )


def _to_dms(value: float, pos_label: str, neg_label: str):
    direction = pos_label if value >= 0 else neg_label
    abs_value = abs(value)
    degrees = int(abs_value)
    minutes_full = (abs_value - degrees) * 60.0
    minutes = int(minutes_full)
    seconds = (minutes_full - minutes) * 60.0
    return degrees, minutes, seconds, direction


def _send_fcm_notification(
    user_id: str,
    walk_id: str,
    suggest_id: str,
    message_id: str,
    message: str,
    lat: float,
    lon: float,
) -> str | None:
    user = _user_repo().get_user(user_id) or {}
    token = user.get("fcmToken")
    if not isinstance(token, str) or not token:
        current_app.logger.info(
            "fcm_skip user_id=%s reason=no_token", user_id
        )
        return "skipped"

    data = {
        "message": message,
        "walkId": walk_id,
        "suggestId": suggest_id,
        "messageId": message_id,
        "lat": f"{lat:.6f}",
        "lon": f"{lon:.6f}",
    }
    try:
        _fcm_client().send(
            token=token,
            data=data,
            title="ここ面白いかも、、",
            body=message,
        )
    except Exception as exc:
        current_app.logger.warning(
            "fcm_failed user_id=%s error=%s", user_id, exc
        )
        return "failed"
    return "sent"
