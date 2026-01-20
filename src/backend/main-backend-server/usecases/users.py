from datetime import datetime
from typing import Protocol

from domain.errors import AppError
from domain.models import User, UserUpdateResult


class UserRepository(Protocol):
    def upsert_user(self, user_id: str, nickname: str, email: str | None) -> None:
        raise NotImplementedError

    def get_user(self, user_id: str) -> dict | None:
        raise NotImplementedError

    def update_user(
        self,
        user_id: str,
        nickname: str | None = None,
        fcm_token: str | None = None,
    ) -> None:
        raise NotImplementedError

    def delete_user(self, user_id: str) -> None:
        raise NotImplementedError


def create_user(
    repo: UserRepository,
    user_id: str,
    email: str | None,
    nickname: str,
    now: datetime,
) -> User:
    repo.upsert_user(user_id, nickname, email)
    return User(
        user_id=user_id,
        nickname=nickname,
        email=email,
        created_at=now,
        last_login_at=now,
        total_walks=0,
        total_distance_km=0,
    )


def get_user(repo: UserRepository, user_id: str) -> User:
    data = repo.get_user(user_id)
    if data is None:
        raise AppError("USER_NOT_FOUND", "User not found", 404)

    return User(
        user_id=user_id,
        nickname=data.get("nickname"),
        email=data.get("email"),
        created_at=data.get("createdAt"),
        last_login_at=data.get("lastLoginAt"),
        total_walks=data.get("totalWalks", 0),
        total_distance_km=data.get("totalDistanceKm", 0),
    )


def update_user(
    repo: UserRepository,
    user_id: str,
    nickname: str | None,
    fcm_token: str | None,
    now: datetime,
) -> UserUpdateResult:
    if nickname is None and fcm_token is None:
        raise AppError("INVALID_ARGUMENT", "update payload is required", 400)

    repo.update_user(user_id, nickname=nickname, fcm_token=fcm_token)
    return UserUpdateResult(
        user_id=user_id,
        nickname=nickname,
        fcm_token=fcm_token,
        updated_at=now,
    )


def delete_user(repo: UserRepository, user_id: str) -> None:
    repo.delete_user(user_id)
