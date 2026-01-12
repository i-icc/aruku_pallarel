import logging
import os
from datetime import datetime, timezone

from firebase_admin import firestore
from flask import Blueprint, Flask, jsonify, request
from werkzeug.exceptions import HTTPException

import firebase_client
from auth import current_user_email, current_user_id, require_auth
from errors import error_response
from firestore_utils import delete_document_recursive

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))


api_v1 = Blueprint("api_v1", __name__, url_prefix="/v1")


@app.errorhandler(HTTPException)
def handle_http_exception(error):
    code = (error.name or "error").upper().replace(" ", "_")
    return error_response(code, error.description, error.code or 500)


@app.errorhandler(Exception)
def handle_unexpected_exception(error):
    app.logger.exception("Unhandled exception: %s", error)
    return error_response("INTERNAL", "Internal server error", 500)


def to_rfc3339(timestamp):
    if timestamp is None:
        return None
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)
    return timestamp.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


@api_v1.post("/users")
@require_auth
def create_user():
    payload = request.get_json(silent=True) or {}
    nickname = payload.get("nickname")
    if not nickname:
        return error_response("INVALID_ARGUMENT", "nickname is required", 400)

    user_id = current_user_id()
    email = current_user_email()
    now = datetime.now(timezone.utc)

    db = firebase_client.get_firestore_client()
    doc_ref = db.collection("users").document(user_id)
    doc_ref.set(
        {
            "nickname": nickname,
            "email": email,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "lastLoginAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )

    return jsonify(
        userId=user_id,
        nickname=nickname,
        createdAt=to_rfc3339(now),
    )


@api_v1.get("/users/me")
@require_auth
def get_me():
    user_id = current_user_id()

    db = firebase_client.get_firestore_client()
    snapshot = db.collection("users").document(user_id).get()
    if not snapshot.exists:
        return error_response("USER_NOT_FOUND", "User not found", 404)

    data = snapshot.to_dict() or {}
    return jsonify(
        userId=user_id,
        nickname=data.get("nickname"),
        email=data.get("email"),
        createdAt=to_rfc3339(data.get("createdAt")),
        lastLoginAt=to_rfc3339(data.get("lastLoginAt")),
        totalWalks=data.get("totalWalks", 0),
        totalDistanceKm=data.get("totalDistanceKm", 0),
    )


@api_v1.patch("/users/me")
@require_auth
def update_me():
    payload = request.get_json(silent=True) or {}
    nickname = payload.get("nickname")
    if not nickname:
        return error_response("INVALID_ARGUMENT", "nickname is required", 400)

    user_id = current_user_id()
    now = datetime.now(timezone.utc)

    db = firebase_client.get_firestore_client()
    doc_ref = db.collection("users").document(user_id)
    doc_ref.set(
        {
            "nickname": nickname,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )

    return jsonify(
        userId=user_id,
        nickname=nickname,
        updatedAt=to_rfc3339(now),
    )


@api_v1.delete("/users/me")
@require_auth
def delete_me():
    user_id = current_user_id()

    db = firebase_client.get_firestore_client()
    doc_ref = db.collection("users").document(user_id)
    delete_document_recursive(doc_ref)

    return jsonify(result="ok")


@app.get("/")
def index():
    return jsonify(service="backend", status="ok")


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.post("/internal/task-handler")
def task_handler():
    payload = request.get_json(silent=True) or {}
    app.logger.info("task_handler payload=%s", payload)
    return jsonify(status="received", payload=payload)


app.register_blueprint(api_v1)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
