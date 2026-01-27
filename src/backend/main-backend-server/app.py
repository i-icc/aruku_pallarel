import json
import logging
import os
import time

from flask import Flask, jsonify, request
from werkzeug.exceptions import HTTPException

from api.internal import internal_api
from api.locations import locations_api
from api.jobs import jobs_api
from api.users import users_api
from api.walks import walks_api
from domain.errors import AppError
from errors import error_response

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))
REQUEST_LOG_BODY_LIMIT = int(os.getenv("REQUEST_LOG_BODY_LIMIT", "2000"))
ENABLE_JOB_ENDPOINTS = os.getenv("ENABLE_JOB_ENDPOINTS", "")


def _is_truthy(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _truncate_payload(payload):
    try:
        text = json.dumps(payload, ensure_ascii=True)
    except (TypeError, ValueError):
        text = str(payload)
    if len(text) > REQUEST_LOG_BODY_LIMIT:
        return f"{text[:REQUEST_LOG_BODY_LIMIT]}...(truncated)"
    return text


@app.errorhandler(HTTPException)
def handle_http_exception(error):
    code = (error.name or "error").upper().replace(" ", "_")
    return error_response(code, error.description, error.code or 500)


@app.errorhandler(AppError)
def handle_app_error(error):
    return error_response(error.code, error.message, error.status_code)


@app.errorhandler(Exception)
def handle_unexpected_exception(error):
    app.logger.exception("Unhandled exception: %s", error)
    return error_response("INTERNAL", "Internal server error", 500)


@app.get("/")
def index():
    return jsonify(service="backend", status="ok")


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


app.register_blueprint(users_api)
app.register_blueprint(walks_api)
app.register_blueprint(locations_api)
app.register_blueprint(internal_api)
if _is_truthy(ENABLE_JOB_ENDPOINTS):
    app.register_blueprint(jobs_api)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
