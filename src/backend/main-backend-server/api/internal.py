from flask import Blueprint, current_app, jsonify, request

internal_api = Blueprint("internal_api", __name__, url_prefix="/internal")


@internal_api.post("/task-handler")
def task_handler():
    payload = request.get_json(silent=True) or {}
    current_app.logger.info("task_handler payload=%s", payload)
    return jsonify(status="received", payload=payload)
