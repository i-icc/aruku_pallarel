import logging
import os

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "7070"))


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.post("/tasks")
def create_task():
    payload = request.get_json(silent=True) or {}
    target_url = payload.get("target_url")
    task_payload = payload.get("payload", {})
    headers = payload.get("headers", {})
    timeout = int(payload.get("timeout_seconds", 10))

    if not target_url:
        return jsonify(error="target_url is required"), 400

    try:
        response = requests.post(
            target_url,
            json=task_payload,
            headers=headers,
            timeout=timeout,
        )
    except requests.RequestException as exc:
        app.logger.error("dispatch_failed target=%s error=%s", target_url, exc)
        return jsonify(error="dispatch_failed", detail=str(exc)), 502

    app.logger.info(
        "dispatch_ok target=%s status=%s", target_url, response.status_code
    )

    return jsonify(
        status="dispatched",
        target_url=target_url,
        response_status=response.status_code,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
