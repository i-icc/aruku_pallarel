from datetime import datetime, timezone

from geo import (
    distance_point_to_polyline_m,
    distance_point_to_segment_m,
    is_unexplored,
)
from location_models import LocationPoint


def _point(lat, lon):
    return LocationPoint(
        lat=lat, lon=lon, timestamp=datetime(2026, 1, 1, tzinfo=timezone.utc)
    )


def test_distance_point_to_segment_on_line():
    start = _point(0.0, 0.0)
    end = _point(0.0, 0.001)
    target = _point(0.0, 0.0005)
    distance = distance_point_to_segment_m(target, start, end)
    assert distance < 0.5


def test_distance_point_to_segment_offset():
    start = _point(0.0, 0.0)
    end = _point(0.0, 0.001)
    target = _point(0.0001, 0.0005)
    distance = distance_point_to_segment_m(target, start, end)
    assert 10.0 < distance < 12.5


def test_distance_point_to_polyline_matches_segment():
    polyline = [_point(0.0, 0.0), _point(0.0, 0.001)]
    target = _point(0.0001, 0.0005)
    distance = distance_point_to_polyline_m(target, polyline)
    assert 10.0 < distance < 12.5


def test_is_unexplored_threshold():
    polyline = [_point(0.0, 0.0), _point(0.0, 0.001)]
    far_point = _point(0.0001, 0.0005)
    near_point = _point(0.00004, 0.0005)
    assert is_unexplored(far_point, polyline, threshold_m=10.0) is True
    assert is_unexplored(near_point, polyline, threshold_m=10.0) is False
