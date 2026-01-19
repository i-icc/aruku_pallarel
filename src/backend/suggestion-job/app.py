import logging
import os

from flask import Flask, jsonify, request

import firebase_client
from firestore_repositories import FirestoreSuggestionRequestRepository

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))


def _request_repo():
    db = firebase_client.get_firestore_client()
    return FirestoreSuggestionRequestRepository(db)


@app.get("/")
def index():
    return jsonify(service="suggestion-job", status="ok")


@app.get("/health")
def health():
    return jsonify(status="ok")


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
