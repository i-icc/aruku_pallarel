import logging
import math
import random
from dataclasses import dataclass
from datetime import datetime, timezone

from geo import EARTH_RADIUS_M, is_unexplored
from location_models import LocationPoint

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class CandidateResult:
    candidate: LocationPoint
    snapped: LocationPoint
    attempts: int


def select_candidate(
    start: LocationPoint,
    current: LocationPoint,
    polyline: list[LocationPoint],
    osm_client,
    attempts: int = 3,
    rng: random.Random | None = None,
) -> CandidateResult | None:
    rng = rng or random
    radius_m = _diameter_radius_m(start, current)
    center = _midpoint(start, current)

    for attempt in range(1, attempts + 1):
        candidate = _random_point_in_circle(center, radius_m, rng)
        snapped = osm_client.nearest_road(candidate.lat, candidate.lon)
        if is_unexplored(snapped, polyline, threshold_m=10.0):
            return CandidateResult(candidate=candidate, snapped=snapped, attempts=attempt)
        logger.info(
            "candidate_rejected attempt=%s lat=%.6f lon=%.6f",
            attempt,
            snapped.lat,
            snapped.lon,
        )
    return None


def _diameter_radius_m(start: LocationPoint, current: LocationPoint) -> float:
    distance = _haversine_distance_m(start, current)
    return distance / 2.0


def _midpoint(start: LocationPoint, current: LocationPoint) -> LocationPoint:
    return LocationPoint(
        lat=(start.lat + current.lat) / 2.0,
        lon=(start.lon + current.lon) / 2.0,
        timestamp=datetime.now(timezone.utc),
    )


def _random_point_in_circle(
    center: LocationPoint, radius_m: float, rng: random.Random
) -> LocationPoint:
    if radius_m <= 0:
        return center
    angle = rng.random() * 2.0 * math.pi
    radius = math.sqrt(rng.random()) * radius_m
    dx = radius * math.cos(angle)
    dy = radius * math.sin(angle)
    lat, lon = _offset_lat_lon(center.lat, center.lon, dx, dy)
    return LocationPoint(lat=lat, lon=lon, timestamp=datetime.now(timezone.utc))


def _offset_lat_lon(
    lat: float, lon: float, dx_m: float, dy_m: float
) -> tuple[float, float]:
    lat_rad = math.radians(lat)
    dlat = dy_m / EARTH_RADIUS_M
    cos_lat = math.cos(lat_rad)
    if cos_lat == 0:
        dlon = 0
    else:
        dlon = dx_m / (EARTH_RADIUS_M * cos_lat)
    return lat + math.degrees(dlat), lon + math.degrees(dlon)


def _haversine_distance_m(a: LocationPoint, b: LocationPoint) -> float:
    return (
        2
        * EARTH_RADIUS_M
        * math.asin(
            math.sqrt(
                math.sin(math.radians(b.lat - a.lat) / 2) ** 2
                + math.cos(math.radians(a.lat))
                * math.cos(math.radians(b.lat))
                * math.sin(math.radians(b.lon - a.lon) / 2) ** 2
            )
        )
    )
