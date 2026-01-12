from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

import firebase_client
from auth import current_user_email, current_user_id, require_auth
from domain.errors import AppError
from infrastructure.firestore_repositories import FirestoreUserRepository
from usecases.users import create_user, delete_user, get_user, update_user
from utils.time import to_rfc3339

users_api = Blueprint("users_api", __name__, url_prefix="/v1")


def _user_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreUserRepository(db)


@users_api.post("/users")
@require_auth
def create_user_handler():
    payload = request.get_json(silent=True) or {}
    nickname = payload.get("nickname")
    if not nickname:
        raise AppError("INVALID_ARGUMENT", "nickname is required", 400)

    user_id = current_user_id()
    email = current_user_email()
    now = datetime.now(timezone.utc)

    user = create_user(_user_repo(), user_id, email, nickname, now)
    return jsonify(
        userId=user.user_id,
        nickname=user.nickname,
        createdAt=to_rfc3339(user.created_at),
    )


@users_api.get("/users/me")
@require_auth
def get_me_handler():
    user_id = current_user_id()
    user = get_user(_user_repo(), user_id)
    return jsonify(
        userId=user.user_id,
        nickname=user.nickname,
        email=user.email,
        createdAt=to_rfc3339(user.created_at),
        lastLoginAt=to_rfc3339(user.last_login_at),
        totalWalks=user.total_walks,
        totalDistanceKm=user.total_distance_km,
    )


@users_api.patch("/users/me")
@require_auth
def update_me_handler():
    payload = request.get_json(silent=True) or {}
    nickname = payload.get("nickname")
    if not nickname:
        raise AppError("INVALID_ARGUMENT", "nickname is required", 400)

    user_id = current_user_id()
    now = datetime.now(timezone.utc)

    result = update_user(_user_repo(), user_id, nickname, now)
    return jsonify(
        userId=result.user_id,
        nickname=result.nickname,
        updatedAt=to_rfc3339(result.updated_at),
    )


@users_api.delete("/users/me")
@require_auth
def delete_me_handler():
    user_id = current_user_id()
    delete_user(_user_repo(), user_id)
    return jsonify(result="ok")
