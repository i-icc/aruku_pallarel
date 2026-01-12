from datetime import datetime, timedelta
from typing import Protocol

from domain.errors import AppError
from domain.models import Location, SuggestionRequestResult, Walk
from utils.time import ensure_utc, to_rfc3339


class WalkRepository(Protocol):
    def create_walk(self, user_id: str, walk_id: str, start_location: Location) -> bool:
        raise NotImplementedError

    def get_walk(self, user_id: str, walk_id: str) -> dict | None:
        raise NotImplementedError

    def finish_walk(self, user_id: str, walk_id: str) -> None:
        raise NotImplementedError

    def update_last_suggestion_at(self, user_id: str, walk_id: str) -> None:
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
    tasks_queue: TasksQueue,
    user_id: str,
    walk_id: str,
    now: datetime,
    cooldown_minutes: int = 5,
) -> SuggestionRequestResult:
    data = repo.get_walk(user_id, walk_id)
    if data is None:
        raise AppError("WALK_NOT_FOUND", "Walk not found", 404)

    if data.get("status") != "active":
        return SuggestionRequestResult(result="ng", reason="walk_inactive")

    last_suggestion_at = data.get("lastSuggestionAt")
    last_suggestion_at = ensure_utc(last_suggestion_at)
    if last_suggestion_at and now - last_suggestion_at < timedelta(
        minutes=cooldown_minutes
    ):
        return SuggestionRequestResult(result="ng", reason="cooldown")

    payload = {"userId": user_id, "walkId": walk_id, "requestedAt": to_rfc3339(now)}
    if not tasks_queue.enqueue_suggestion(payload):
        return SuggestionRequestResult(result="ng", reason="enqueue_failed")

    repo.update_last_suggestion_at(user_id, walk_id)
    return SuggestionRequestResult(result="ok", reason=None)
