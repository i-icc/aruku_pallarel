from flask import Blueprint, jsonify, request

from firebase_client import get_firestore_client
from jobs.adk_client import AdkClient
from jobs.candidate_selector import select_candidate
from jobs.firestore_repositories import (
    FirestoreSuggestionRequestRepository,
    FirestoreWalkRepository,
)
from jobs.location_models import LocationPoint
from jobs.osm_client import OsmClient

jobs_api = Blueprint("jobs_api", __name__, url_prefix="/jobs")


def _request_repo():
    db = get_firestore_client()
    return FirestoreSuggestionRequestRepository(db)


def _walk_repo():
    db = get_firestore_client()
    return FirestoreWalkRepository(db)


def _osm_client():
    return OsmClient()


def _adk_client():
    return AdkClient()


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

    request_repo.update_status(
        request_id, "failed", error="not_implemented_after_adk"
    )
    return jsonify(
        status="failed",
        requestId=request_id,
        error="not_implemented_after_adk",
        message=message,
        candidateLat=candidate.candidate.lat,
        candidateLon=candidate.candidate.lon,
        snappedLat=candidate.snapped.lat,
        snappedLon=candidate.snapped.lon,
        attempts=candidate.attempts,
    )


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
