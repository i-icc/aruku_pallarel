import logging
import os

from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

from api.internal import internal_api
from api.users import users_api
from api.walks import walks_api
from domain.errors import AppError
from errors import error_response

app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

PORT = int(os.getenv("PORT", "8080"))


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


app.register_blueprint(users_api)
app.register_blueprint(walks_api)
app.register_blueprint(internal_api)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
