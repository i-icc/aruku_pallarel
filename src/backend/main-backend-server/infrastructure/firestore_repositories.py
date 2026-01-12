from firebase_admin import firestore

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

    def update_user(self, user_id, nickname):
        doc_ref = self._db.collection("users").document(user_id)
        doc_ref.set(
            {
                "nickname": nickname,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

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
                    "suggestCount": 0,
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

    def update_last_suggestion_at(self, user_id, walk_id):
        walk_ref = self._walks_ref(user_id).document(walk_id)
        walk_ref.set(
            {"lastSuggestionAt": firestore.SERVER_TIMESTAMP},
            merge=True,
        )
