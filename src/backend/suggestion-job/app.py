import json
import logging
import os
import time

from flask import Flask, jsonify, request

import firebase_client
from firestore_repositories import FirestoreSuggestionRequestRepository

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))
REQUEST_LOG_BODY_LIMIT = int(os.getenv("REQUEST_LOG_BODY_LIMIT", "2000"))


def _truncate_payload(payload):
    try:
        text = json.dumps(payload, ensure_ascii=True)
    except (TypeError, ValueError):
        text = str(payload)
    if len(text) > REQUEST_LOG_BODY_LIMIT:
        return f"{text[:REQUEST_LOG_BODY_LIMIT]}...(truncated)"
    return text


def _request_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreSuggestionRequestRepository(db)


@app.get("/")
def index():
    return jsonify(service="suggestion-job", status="ok")


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.before_request
def log_request():
    request._start_time = time.monotonic()
    payload = request.get_json(silent=True)
    if payload is None:
        app.logger.info("request %s %s", request.method, request.path)
    else:
        app.logger.info(
            "request %s %s payload=%s",
            request.method,
            request.path,
            _truncate_payload(payload),
        )


@app.after_request
def log_response(response):
    duration_ms = None
    if hasattr(request, "_start_time"):
        duration_ms = int((time.monotonic() - request._start_time) * 1000)
    payload = None
    if response.mimetype == "application/json":
        payload = response.get_json(silent=True)
    if payload is None:
        app.logger.info(
            "response %s %s status=%s duration_ms=%s",
            request.method,
            request.path,
            response.status_code,
            duration_ms,
        )
    else:
        app.logger.info(
            "response %s %s status=%s duration_ms=%s payload=%s",
            request.method,
            request.path,
            response.status_code,
            duration_ms,
            _truncate_payload(payload),
        )
    return response


@app.post("/jobs/suggestions")
def run_suggestion_job():
    payload = request.get_json(silent=True) or {}
    request_id = payload.get("requestId")
    if not request_id:
        return jsonify(error="requestId is required"), 400

    repo = _request_repo()
    request_data = repo.get_request(request_id)
    if request_data is None:
        return jsonify(error="request_not_found"), 404

    status = request_data.get("status")
    if status != "queued":
        return jsonify(status="ignored", requestId=request_id, requestStatus=status)

    repo.update_status(request_id, "running")
    repo.update_status(request_id, "failed", error="not_implemented")
    return jsonify(status="failed", requestId=request_id)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
