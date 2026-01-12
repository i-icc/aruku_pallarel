from functools import wraps

from flask import g, request

import firebase_client
from errors import error_response


def require_auth(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return error_response("UNAUTHORIZED", "Missing bearer token", 401)

        token = header.split(" ", 1)[1].strip()
        if not token:
            return error_response("UNAUTHORIZED", "Missing bearer token", 401)

        try:
            decoded = firebase_client.verify_id_token(token)
        except Exception:
            return error_response("UNAUTHORIZED", "Invalid token", 401)

        user_id = decoded.get("uid") or decoded.get("user_id")
        if not user_id:
            return error_response("UNAUTHORIZED", "Invalid token", 401)

        g.user_id = user_id
        g.user_email = decoded.get("email")
        return view(*args, **kwargs)

    return wrapped


def current_user_id():
    return getattr(g, "user_id", None)


def current_user_email():
    return getattr(g, "user_email", None)
