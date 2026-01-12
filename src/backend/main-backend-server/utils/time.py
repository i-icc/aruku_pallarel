from datetime import timezone


def ensure_utc(timestamp):
    if timestamp is None:
        return None
    if timestamp.tzinfo is None:
        return timestamp.replace(tzinfo=timezone.utc)
    return timestamp.astimezone(timezone.utc)


def to_rfc3339(timestamp):
    if timestamp is None:
        return None
    return ensure_utc(timestamp).isoformat().replace("+00:00", "Z")
