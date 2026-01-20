from datetime import datetime, timezone

from firebase_admin import firestore

from domain.models import LocationPoint
from utils.time import ensure_utc

from firestore_utils import delete_document_recursive


class FirestoreUserRepository:
    def __init__(self, db):
        self._db = db

    def upsert_user(self, user_id, nickname, email):
        doc_ref = self._db.collection("users").document(user_id)
        doc_ref.set(
            {
                "nickname": nickname,
                "email": email,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "lastLoginAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

    def get_user(self, user_id):
        snapshot = self._db.collection("users").document(user_id).get()
        if not snapshot.exists:
            return None
        return snapshot.to_dict() or {}

    def update_user(self, user_id, nickname=None, fcm_token=None):
        doc_ref = self._db.collection("users").document(user_id)
        data = {"updatedAt": firestore.SERVER_TIMESTAMP}
        if nickname is not None:
            data["nickname"] = nickname
        if fcm_token is not None:
            data["fcmToken"] = fcm_token
        doc_ref.set(data, merge=True)

    def delete_user(self, user_id):
        doc_ref = self._db.collection("users").document(user_id)
        delete_document_recursive(doc_ref)


class FirestoreWalkRepository:
    def __init__(self, db):
        self._db = db

    def _walks_ref(self, user_id):
        return self._db.collection("users").document(user_id).collection("walks")

    def create_walk(self, user_id, walk_id, start_location):
        walks_ref = self._walks_ref(user_id)
        walk_ref = walks_ref.document(walk_id)
        transaction = self._db.transaction()

        @firestore.transactional
        def _create(transaction_obj):
            active_query = walks_ref.where("status", "==", "active").limit(1)
            active_snapshots = list(transaction_obj.get(active_query))
            if active_snapshots:
                return False

            transaction_obj.set(
                walk_ref,
                {
                    "status": "active",
                    "startedAt": firestore.SERVER_TIMESTAMP,
                    "startLocation": firestore.GeoPoint(
                        start_location.lat, start_location.lon
                    ),
                },
            )
            return True

        return _create(transaction)

    def get_walk(self, user_id, walk_id):
        snapshot = self._walks_ref(user_id).document(walk_id).get()
        if not snapshot.exists:
            return None
        return snapshot.to_dict() or {}

    def finish_walk(self, user_id, walk_id):
        walk_ref = self._walks_ref(user_id).document(walk_id)
        walk_ref.set(
            {
                "status": "finished",
                "finishedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

    def get_location_points(self, user_id, walk_id):
        locations_ref = (
            self._walks_ref(user_id).document(walk_id).collection("locations")
        )
        snapshots = list(locations_ref.stream())
        batches = []
        for snapshot in snapshots:
            data = snapshot.to_dict() or {}
            index = data.get("index", 0)
            points = data.get("points", [])
            batches.append((index, points))

        batches.sort(key=lambda entry: entry[0])
        flattened = []
        for _, points in batches:
            for point in points:
                timestamp = point.get("timestamp")
                geo = point.get("geo")
                if timestamp is None or geo is None:
                    continue
                if hasattr(geo, "latitude") and hasattr(geo, "longitude"):
                    lat = geo.latitude
                    lon = geo.longitude
                elif isinstance(geo, dict):
                    lat = geo.get("lat", geo.get("latitude"))
                    lon = geo.get("lon", geo.get("longitude"))
                else:
                    continue
                if not isinstance(lat, (int, float)) or not isinstance(
                    lon, (int, float)
                ):
                    continue
                flattened.append(
                    LocationPoint(
                        lat=lat,
                        lon=lon,
                        timestamp=ensure_utc(timestamp),
                    )
                )

        flattened.sort(key=lambda entry: entry.timestamp)
        return flattened


class FirestoreSuggestionRequestRepository:
    def __init__(self, db):
        self._db = db

    def _requests_ref(self):
        return self._db.collection("requests")

    def create_request(self, request_id, user_id, walk_id, requested_at):
        doc_ref = self._requests_ref().document(request_id)
        doc_ref.set(
            {
                "requestId": request_id,
                "userId": user_id,
                "walkId": walk_id,
                "requestedAt": requested_at,
                "status": "queued",
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )

    def delete_request(self, request_id):
        self._requests_ref().document(request_id).delete()

    def get_latest_request(self, user_id, walk_id):
        snapshots = self._requests_ref().stream()
        candidates = []
        for snapshot in snapshots:
            data = snapshot.to_dict() or {}
            if data.get("userId") == user_id and data.get("walkId") == walk_id:
                requested_at = ensure_utc(data.get("requestedAt"))
                candidates.append((requested_at, data))
        if not candidates:
            return None
        min_time = datetime.min.replace(tzinfo=timezone.utc)
        candidates.sort(
            key=lambda entry: entry[0] or min_time,
            reverse=True,
        )
        return candidates[0][1]
