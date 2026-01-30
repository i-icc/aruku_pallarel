from datetime import datetime, timezone


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


def parse_rfc3339(value):
    if value is None:
        return None
    if isinstance(value, datetime):
        return ensure_utc(value)
    if isinstance(value, str):
        try:
            normalized = value.replace("Z", "+00:00")
            return ensure_utc(datetime.fromisoformat(normalized))
        except ValueError:
            return None
    return None
