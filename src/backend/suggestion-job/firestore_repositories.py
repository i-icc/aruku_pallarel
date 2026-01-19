from firebase_admin import firestore


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
