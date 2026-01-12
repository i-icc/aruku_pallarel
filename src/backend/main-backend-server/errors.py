from flask import jsonify


def error_response(code: str, message: str, status_code: int):
    return jsonify(error={"code": code, "message": message}), status_code
