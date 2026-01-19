import math

from location_models import LocationPoint

EARTH_RADIUS_M = 6371000.0


def haversine_distance_m(lat1, lon1, lat2, lon2):
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.asin(math.sqrt(a))
    return EARTH_RADIUS_M * c


def distance_point_to_segment_m(point: LocationPoint, start: LocationPoint, end: LocationPoint) -> float:
    ref_lat = point.lat
    px, py = _to_xy(point.lat, point.lon, ref_lat)
    sx, sy = _to_xy(start.lat, start.lon, ref_lat)
    ex, ey = _to_xy(end.lat, end.lon, ref_lat)

    dx = ex - sx
    dy = ey - sy
    if dx == 0 and dy == 0:
        return math.hypot(px - sx, py - sy)

    t = ((px - sx) * dx + (py - sy) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    closest_x = sx + t * dx
    closest_y = sy + t * dy
    return math.hypot(px - closest_x, py - closest_y)


def distance_point_to_polyline_m(point: LocationPoint, polyline: list[LocationPoint]) -> float:
    if not polyline:
        return float("inf")
    if len(polyline) == 1:
        only = polyline[0]
        return haversine_distance_m(point.lat, point.lon, only.lat, only.lon)

    min_distance = float("inf")
    for start, end in zip(polyline[:-1], polyline[1:]):
        distance = distance_point_to_segment_m(point, start, end)
        if distance < min_distance:
            min_distance = distance
    return min_distance


def is_unexplored(
    point: LocationPoint, polyline: list[LocationPoint], threshold_m: float = 10.0
) -> bool:
    return distance_point_to_polyline_m(point, polyline) > threshold_m


def _to_xy(lat, lon, ref_lat):
    lat_rad = math.radians(lat)
    lon_rad = math.radians(lon)
    ref_lat_rad = math.radians(ref_lat)
    x = EARTH_RADIUS_M * lon_rad * math.cos(ref_lat_rad)
    y = EARTH_RADIUS_M * lat_rad
    return x, y
