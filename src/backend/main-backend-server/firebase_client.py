import os

import firebase_admin
from firebase_admin import auth, firestore

_app = None


def init_firebase_app():
    global _app
    if _app is not None:
        return _app

    project_id = os.getenv("PROJECT_ID")
    if not project_id:
        raise RuntimeError("PROJECT_ID is required")

    _app = firebase_admin.initialize_app(options={"projectId": project_id})
    return _app


def get_firestore_client():
    init_firebase_app()
    return firestore.client()


def verify_id_token(token: str):
    init_firebase_app()
    return auth.verify_id_token(token)
