import logging
from datetime import datetime, timedelta
from typing import Protocol
from uuid import uuid4

from domain.errors import AppError
from domain.models import Location, LocationPoint, SuggestionRequestResult, Walk
from utils.geo import haversine_distance_m
from utils.time import ensure_utc

logger = logging.getLogger(__name__)


class WalkRepository(Protocol):
    def create_walk(self, user_id: str, walk_id: str, start_location: Location) -> bool:
        raise NotImplementedError

    def get_walk(self, user_id: str, walk_id: str) -> dict | None:
        raise NotImplementedError

    def finish_walk(self, user_id: str, walk_id: str) -> None:
        raise NotImplementedError

    def get_location_points(self, user_id: str, walk_id: str) -> list[LocationPoint]:
        raise NotImplementedError

    def record_location_points(
        self, user_id: str, walk_id: str, points: list[LocationPoint]
    ) -> None:
        raise NotImplementedError


class SuggestionRequestRepository(Protocol):
    def create_request(
        self, request_id: str, user_id: str, walk_id: str, requested_at: datetime
    ) -> None:
        raise NotImplementedError

    def delete_request(self, request_id: str) -> None:
        raise NotImplementedError

    def get_latest_request(self, user_id: str, walk_id: str) -> dict | None:
        raise NotImplementedError


class TasksQueue(Protocol):
    def enqueue_suggestion(self, payload: dict) -> bool:
        raise NotImplementedError


def start_walk(
    repo: WalkRepository,
    user_id: str,
    walk_id: str,
    start_location: Location,
    now: datetime,
) -> Walk:
    created = repo.create_walk(user_id, walk_id, start_location)
    if not created:
        raise AppError("WALK_ALREADY_ACTIVE", "Walk already active", 409)

    return Walk(
        walk_id=walk_id,
        status="active",
        started_at=now,
        finished_at=None,
    )


def finish_walk(
    repo: WalkRepository,
    user_id: str,
    walk_id: str,
    now: datetime,
) -> Walk:
    data = repo.get_walk(user_id, walk_id)
    if data is None:
        raise AppError("WALK_NOT_FOUND", "Walk not found", 404)

    repo.finish_walk(user_id, walk_id)
    return Walk(
        walk_id=walk_id,
        status="finished",
        started_at=None,
        finished_at=now,
    )


def request_suggestion(
    repo: WalkRepository,
    requests_repo: SuggestionRequestRepository,
    tasks_queue: TasksQueue,
    user_id: str,
    walk_id: str,
    now: datetime,
    cooldown_minutes: int = 5,
    min_distance_meters: float = 250.0,
) -> SuggestionRequestResult:
    data = repo.get_walk(user_id, walk_id)
    if data is None:
        raise AppError("WALK_NOT_FOUND", "Walk not found", 404)

    if data.get("status") != "active":
        logger.info(
            "suggestion_request_ng reason=walk_inactive user_id=%s walk_id=%s status=%s",
            user_id,
            walk_id,
            data.get("status"),
        )
        return SuggestionRequestResult(result="ng", request_id=None, reason="walk_inactive")

    latest_request = requests_repo.get_latest_request(user_id, walk_id)
    baseline_time = (
        ensure_utc(latest_request.get("requestedAt")) if latest_request else None
    )
    if baseline_time and now - baseline_time < timedelta(
        minutes=cooldown_minutes
    ):
        logger.info(
            "suggestion_request_ng reason=cooldown user_id=%s walk_id=%s now=%s baseline=%s",
            user_id,
            walk_id,
            now.isoformat(),
            baseline_time.isoformat(),
        )
        return SuggestionRequestResult(result="ng", request_id=None, reason="cooldown")

    distance_meters, points_total, points_used = _distance_since(
        repo,
        user_id,
        walk_id,
        data,
        baseline_time,
        latest_request is None,
    )
    if distance_meters < min_distance_meters:
        logger.info(
            "suggestion_request_ng reason=distance_short user_id=%s walk_id=%s distance_m=%.1f min_distance=%.1f points_total=%s points_used=%s baseline=%s",
            user_id,
            walk_id,
            distance_meters,
            min_distance_meters,
            points_total,
            points_used,
            baseline_time.isoformat() if baseline_time else None,
        )
        return SuggestionRequestResult(result="ng", request_id=None, reason="distance_short")

    request_id = uuid4().hex
    requests_repo.create_request(request_id, user_id, walk_id, now)

    payload = {"requestId": request_id, "userId": user_id, "walkId": walk_id}
    if not tasks_queue.enqueue_suggestion(payload):
        logger.info(
            "suggestion_request_ng reason=enqueue_failed user_id=%s walk_id=%s request_id=%s",
            user_id,
            walk_id,
            request_id,
        )
        requests_repo.delete_request(request_id)
        return SuggestionRequestResult(result="ng", request_id=None, reason="enqueue_failed")

    logger.info(
        "suggestion_request_ok user_id=%s walk_id=%s request_id=%s distance_m=%.1f points_used=%s",
        user_id,
        walk_id,
        request_id,
        distance_meters,
        points_used,
    )
    return SuggestionRequestResult(result="ok", request_id=request_id, reason=None)


def _distance_since(
    repo: WalkRepository,
    user_id: str,
    walk_id: str,
    walk_data: dict,
    baseline_time: datetime | None,
    include_start_location: bool,
) -> tuple[float, int, int]:
    points = repo.get_location_points(user_id, walk_id)
    total_points = len(points)
    if not points:
        return 0.0, total_points, 0

    if baseline_time:
        points = [point for point in points if point.timestamp >= baseline_time]
    used_points = len(points)
    if not points:
        return 0.0, total_points, used_points

    total = 0.0
    if include_start_location:
        start_location = walk_data.get("startLocation")
        start_coords = _extract_lat_lon(start_location)
        if start_coords:
            prev_lat, prev_lon = start_coords
            for point in points:
                total += haversine_distance_m(
                    prev_lat, prev_lon, point.lat, point.lon
                )
                prev_lat, prev_lon = point.lat, point.lon
            return total, total_points, used_points

    prev = points[0]
    for point in points[1:]:
        total += haversine_distance_m(prev.lat, prev.lon, point.lat, point.lon)
        prev = point
    return total, total_points, used_points


def record_locations(
    repo: WalkRepository,
    requests_repo: SuggestionRequestRepository,
    tasks_queue: TasksQueue,
    user_id: str,
    walk_id: str,
    points: list[LocationPoint],
    now: datetime,
    cooldown_minutes: int = 5,
    min_distance_meters: float = 250.0,
) -> None:
    data = repo.get_walk(user_id, walk_id)
    if data is None:
        raise AppError("WALK_NOT_FOUND", "Walk not found", 404)

    if data.get("status") != "active":
        logger.info(
            "record_locations_skipped walk_inactive user_id=%s walk_id=%s",
            user_id,
            walk_id,
        )
        return

    repo.record_location_points(user_id, walk_id, points)

    # Automatically check and trigger suggestion
    try:
        request_suggestion(
            repo,
            requests_repo,
            tasks_queue,
            user_id,
            walk_id,
            now,
            cooldown_minutes=cooldown_minutes,
            min_distance_meters=min_distance_meters,
        )
    except Exception as e:
        # Don't fail the location recording if suggestion fails
        logger.error("Failed to trigger suggestion in record_locations: %s", e)


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
