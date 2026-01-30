from firebase_admin import firestore


class FakeDocSnapshot:
    def __init__(self, data, doc_id, reference):
        self._data = data
        self.id = doc_id
        self.reference = reference

    @property
    def exists(self):
        return self._data is not None

    def to_dict(self):
        return self._data


class FakeDocRef:
    def __init__(self, store, path, now):
        self._store = store
        self._path = tuple(path)
        self._now = now

    def set(self, data, merge=False):
        existing = self._store.get(self._path, {}) if merge else {}
        resolved = {}
        for key, value in data.items():
            resolved[key] = self._resolve_value(key, value, existing)

        if merge and self._path in self._store:
            merged = dict(existing)
            merged.update(resolved)
            self._store[self._path] = merged
        else:
            self._store[self._path] = resolved

    def _resolve_value(self, key, value, existing):
        if value is firestore.SERVER_TIMESTAMP:
            return self._now

        if self._is_increment(value):
            increment_by = self._get_increment_value(value)
            current = existing.get(key, 0)
            if not isinstance(current, (int, float)):
                current = 0
            return current + (increment_by or 0)

        if self._is_array_union(value):
            values = self._get_array_union_values(value)
            current = existing.get(key, [])
            if not isinstance(current, list):
                current = []
            merged = list(current)
            for item in values:
                if item not in merged:
                    merged.append(item)
            return merged

        return value

    def _is_increment(self, value):
        return value.__class__.__name__ == "Increment"

    def _is_array_union(self, value):
        return value.__class__.__name__ == "ArrayUnion"

    def _get_increment_value(self, value):
        for attr in ("value", "_value", "amount", "_amount"):
            if hasattr(value, attr):
                return getattr(value, attr)
        return None

    def _get_array_union_values(self, value):
        for attr in ("values", "_values", "value"):
            if hasattr(value, attr):
                return list(getattr(value, attr))
        return []

    def get(self):
        data = self._store.get(self._path)
        return FakeDocSnapshot(data, self._path[-1], self)

    def delete(self):
        self._store.pop(self._path, None)

    def collection(self, name):
        return FakeCollection(self._store, list(self._path) + [name], self._now)

    def collections(self):
        prefix = self._path
        collection_names = set()
        for key in self._store.keys():
            if len(key) >= len(prefix) + 2 and key[: len(prefix)] == prefix:
                collection_names.add(key[len(prefix)])
        return [
            FakeCollection(self._store, list(prefix) + [name], self._now)
            for name in sorted(collection_names)
        ]


class FakeQuery:
    def __init__(self, store, path, now, filters=None, limit_count=None):
        self._store = store
        self._path = tuple(path)
        self._now = now
        self._filters = filters or []
        self._limit = limit_count

    def where(self, field_path, op_string, value):
        if op_string != "==":
            raise NotImplementedError("Only == is supported")
        return FakeQuery(
            self._store,
            self._path,
            self._now,
            filters=self._filters + [(field_path, op_string, value)],
            limit_count=self._limit,
        )

    def limit(self, count):
        return FakeQuery(
            self._store,
            self._path,
            self._now,
            filters=self._filters,
            limit_count=count,
        )

    def stream(self, transaction=None):
        prefix = self._path
        snapshots = []
        for key, value in list(self._store.items()):
            if len(key) == len(prefix) + 1 and key[: len(prefix)] == prefix:
                if self._matches(value):
                    doc_id = key[-1]
                    ref = FakeDocRef(self._store, list(prefix) + [doc_id], self._now)
                    snapshots.append(FakeDocSnapshot(value, doc_id, ref))
        if self._limit is not None:
            snapshots = snapshots[: self._limit]
        for snapshot in snapshots:
            yield snapshot

    def _matches(self, data):
        for field_path, op_string, value in self._filters:
            if op_string == "==":
                if data.get(field_path) != value:
                    return False
            else:
                raise NotImplementedError("Only == is supported")
        return True


class FakeCollection:
    def __init__(self, store, path, now):
        self._store = store
        self._path = tuple(path)
        self._now = now

    def document(self, doc_id):
        return FakeDocRef(self._store, list(self._path) + [doc_id], self._now)

    def stream(self):
        prefix = self._path
        for key, value in list(self._store.items()):
            if len(key) == len(prefix) + 1 and key[: len(prefix)] == prefix:
                doc_id = key[-1]
                ref = FakeDocRef(self._store, list(prefix) + [doc_id], self._now)
                yield FakeDocSnapshot(value, doc_id, ref)

    def where(self, field_path, op_string, value):
        return FakeQuery(self._store, self._path, self._now).where(
            field_path, op_string, value
        )


class FakeTransaction:
    def __init__(self, client):
        self._client = client
        self._write_pbs = []
        self._read_only = False
        self._max_attempts = 1
        self._id = None
        self._in_progress = False

    @property
    def id(self):
        return self._id

    @property
    def in_progress(self):
        return self._in_progress

    def get(self, target):
        if isinstance(target, FakeQuery):
            return target.stream()
        if isinstance(target, FakeDocRef):
            return target.get()
        raise TypeError("Unsupported target for transaction.get")

    def set(self, doc_ref, data, merge=False):
        self._write_pbs.append((doc_ref, data))
        doc_ref.set(data, merge=merge)

    def commit(self):
        return self._commit()

    def rollback(self):
        return self._rollback()

    def _clean_up(self):
        self._id = None
        self._in_progress = False
        self._write_pbs = []

    def _begin(self, retry_id=None):
        self._id = retry_id or b"fake-transaction"
        self._in_progress = True

    def _commit(self):
        self._in_progress = False
        return []

    def _rollback(self):
        self._in_progress = False
        return None


class FakeFirestoreClient:
    def __init__(self, now):
        self._store = {}
        self._now = now

    def collection(self, name):
        return FakeCollection(self._store, [name], self._now)

    def transaction(self):
        return FakeTransaction(self)
