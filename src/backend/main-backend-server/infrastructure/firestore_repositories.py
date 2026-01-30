from datetime import datetime, timezone

from firebase_admin import firestore

from domain.models import LocationPoint
from utils.time import ensure_utc

from firestore_utils import delete_document_recursive


def _increment(value: int):
    if hasattr(firestore, "Increment"):
        return firestore.Increment(value)
    if hasattr(firestore, "FieldValue"):
        return firestore.FieldValue.increment(value)
    try:
        from google.cloud.firestore_v1 import Increment
    except ImportError:
        from google.cloud.firestore import Increment  # type: ignore[no-redef]
    return Increment(value)


def _array_union(values):
    if hasattr(firestore, "ArrayUnion"):
        return firestore.ArrayUnion(values)
    if hasattr(firestore, "FieldValue"):
        return firestore.FieldValue.arrayUnion(values)
    try:
        from google.cloud.firestore_v1 import ArrayUnion
    except ImportError:
        from google.cloud.firestore import ArrayUnion  # type: ignore[no-redef]
    return ArrayUnion(values)


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

    def append_location_points(
        self, user_id, walk_id, points, max_batch_size=64
    ):
        if not points:
            return 0

        locations_ref = (
            self._walks_ref(user_id).document(walk_id).collection("locations")
        )
        snapshots = list(locations_ref.stream())

        counts = {}
        existing_indices = set()
        for snapshot in snapshots:
            data = snapshot.to_dict() or {}
            index_value = data.get("index")
            index = (
                index_value
                if isinstance(index_value, int)
                else int(snapshot.id) if snapshot.id.isdigit() else 0
            )
            if index <= 0:
                continue
            count_value = data.get("count")
            if isinstance(count_value, int):
                count = count_value
            else:
                points_list = data.get("points", [])
                count = len(points_list) if isinstance(points_list, list) else 0
            counts[index] = count
            existing_indices.add(index)

        current_index = max(existing_indices) if existing_indices else 1
        current_count = counts.get(current_index, 0)

        points_sorted = sorted(points, key=lambda entry: entry.timestamp)
        payloads_by_index = {}
        for point in points_sorted:
            if current_count >= max_batch_size:
                current_index += 1
                current_count = counts.get(current_index, 0)
            payloads_by_index.setdefault(current_index, []).append(
                {
                    "timestamp": ensure_utc(point.timestamp),
                    "geo": firestore.GeoPoint(point.lat, point.lon),
                }
            )
            current_count += 1
            counts[current_index] = current_count

        for index, payloads in payloads_by_index.items():
            data = {
                "index": index,
                "count": _increment(len(payloads)),
                "points": _array_union(payloads),
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
            if index not in existing_indices:
                data["createdAt"] = firestore.SERVER_TIMESTAMP
            locations_ref.document(str(index)).set(data, merge=True)

        return len(points_sorted)

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
