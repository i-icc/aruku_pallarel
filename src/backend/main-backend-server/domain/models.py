from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class Location:
    lat: float
    lon: float


@dataclass(frozen=True)
class LocationPoint:
    lat: float
    lon: float
    timestamp: datetime


@dataclass(frozen=True)
class User:
    user_id: str
    nickname: str | None
    email: str | None
    created_at: datetime | None
    last_login_at: datetime | None
    total_walks: int
    total_distance_km: float


@dataclass(frozen=True)
class UserUpdateResult:
    user_id: str
    nickname: str
    updated_at: datetime


@dataclass(frozen=True)
class Walk:
    walk_id: str
    status: str
    started_at: datetime | None
    finished_at: datetime | None


@dataclass(frozen=True)
class SuggestionRequestResult:
    result: str
    request_id: str | None
    reason: str | None
