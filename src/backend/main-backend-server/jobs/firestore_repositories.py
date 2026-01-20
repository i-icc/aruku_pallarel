from firebase_admin import firestore

from .location_models import LocationPoint
from .time_utils import ensure_utc


class FirestoreSuggestionRequestRepository:
    def __init__(self, db):
        self._db = db

    def _requests_ref(self):
        return self._db.collection("requests")

    def get_request(self, request_id):
        snapshot = self._requests_ref().document(request_id).get()
        if not snapshot.exists:
            return None
        return snapshot.to_dict() or {}

    def update_status(
        self, request_id, status, error=None, suggest_id=None, message_id=None
    ):
        data = {
            "status": status,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
        if error:
            data["error"] = error
        if suggest_id:
            data["suggestId"] = suggest_id
        if message_id:
            data["messageId"] = message_id
        self._requests_ref().document(request_id).set(data, merge=True)


class FirestoreUserRepository:
    def __init__(self, db):
        self._db = db

    def get_user(self, user_id):
        snapshot = self._db.collection("users").document(user_id).get()
        if not snapshot.exists:
            return None
        return snapshot.to_dict() or {}


class FirestoreWalkRepository:
    def __init__(self, db):
        self._db = db

    def get_walk(self, user_id, walk_id):
        snapshot = (
            self._db.collection("users")
            .document(user_id)
            .collection("walks")
            .document(walk_id)
            .get()
        )
        if not snapshot.exists:
            return None
        return snapshot.to_dict() or {}

    def get_location_points(self, user_id, walk_id):
        locations_ref = (
            self._db.collection("users")
            .document(user_id)
            .collection("walks")
            .document(walk_id)
            .collection("locations")
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
                timestamp = ensure_utc(point.get("timestamp"))
                geo = point.get("geo")
                coords = _extract_lat_lon(geo)
                if timestamp is None or coords is None:
                    continue
                lat, lon = coords
                flattened.append(
                    LocationPoint(lat=lat, lon=lon, timestamp=timestamp)
                )

        flattened.sort(key=lambda entry: entry.timestamp)
        return flattened


class FirestoreChatRepository:
    def __init__(self, db):
        self._db = db

    def _chat_ref(self, user_id, walk_id):
        return (
            self._db.collection("users")
            .document(user_id)
            .collection("walks")
            .document(walk_id)
            .collection("chat")
        )

    def create_message(
        self,
        user_id,
        walk_id,
        chat_id,
        message,
        url=None,
        suggest_id=None,
    ):
        data = {
            "chatId": chat_id,
            "senderType": "system",
            "message": message,
            "createdAt": firestore.SERVER_TIMESTAMP,
        }
        if url:
            data["url"] = url
        if suggest_id:
            data["suggestId"] = suggest_id
        self._chat_ref(user_id, walk_id).document(chat_id).set(data)


class FirestoreSuggestRepository:
    def __init__(self, db):
        self._db = db

    def _suggests_ref(self, user_id, walk_id):
        return (
            self._db.collection("users")
            .document(user_id)
            .collection("walks")
            .document(walk_id)
            .collection("suggests")
        )

    def create_suggest(self, user_id, walk_id, suggest_id, message_id, lat, lon):
        self._suggests_ref(user_id, walk_id).document(suggest_id).set(
            {
                "suggestId": suggest_id,
                "suggestedAt": firestore.SERVER_TIMESTAMP,
                "messageId": message_id,
                "geo": firestore.GeoPoint(lat, lon),
            }
        )


def _extract_lat_lon(value):
    if value is None:
        return None
    if hasattr(value, "latitude") and hasattr(value, "longitude"):
        return value.latitude, value.longitude
    if isinstance(value, dict):
        lat = value.get("lat", value.get("latitude"))
        lon = value.get("lon", value.get("longitude"))
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            return lat, lon
    return None
