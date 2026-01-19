import random
from datetime import datetime, timezone

from candidate_selector import select_candidate
from location_models import LocationPoint


class FakeOsmClient:
    def nearest_road(self, lat, lon):
        return LocationPoint(
            lat=lat, lon=lon, timestamp=datetime(2026, 1, 1, tzinfo=timezone.utc)
        )


def _point(lat, lon):
    return LocationPoint(
        lat=lat, lon=lon, timestamp=datetime(2026, 1, 1, tzinfo=timezone.utc)
    )


def test_select_candidate_unexplored():
    rng = random.Random(0)
    start = _point(0.0, 0.0)
    current = _point(0.0, 0.002)
    polyline = [_point(1.0, 1.0), _point(1.0, 1.001)]
    result = select_candidate(
        start=start,
        current=current,
        polyline=polyline,
        osm_client=FakeOsmClient(),
        rng=rng,
    )
    assert result is not None
    assert result.attempts == 1
