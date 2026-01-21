import json
import os
import urllib.error
import urllib.request
from datetime import datetime, timezone

from .location_models import LocationPoint


class OsmClient:
    def __init__(self, base_url=None, timeout_seconds=None):
        self._base_url = base_url or os.getenv("OSM_BASE_URL")
        self._timeout_seconds = int(
            timeout_seconds or os.getenv("OSM_TIMEOUT_SECONDS", "10")
        )

    def nearest_road(self, lat: float, lon: float) -> LocationPoint:
        if not self._base_url:
            raise RuntimeError("OSM_BASE_URL is not set")
        url = (
            f"{self._base_url.rstrip('/')}/nearest/v1/driving/{lon},{lat}?number=1"
        )
        request_obj = urllib.request.Request(url, method="GET")

        try:
            with urllib.request.urlopen(
                request_obj, timeout=self._timeout_seconds
            ) as response:
                body = response.read()
        except urllib.error.URLError as exc:
            raise RuntimeError(f"OSM request failed: {exc}") from exc

        try:
            data = json.loads(body.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            raise RuntimeError("OSM response is invalid JSON") from exc

        if data.get("code") != "Ok":
            raise RuntimeError("OSM response error")

        waypoints = data.get("waypoints")
        if not isinstance(waypoints, list) or not waypoints:
            raise RuntimeError("OSM response missing waypoints")

        waypoint = waypoints[0] if isinstance(waypoints[0], dict) else None
        location = waypoint.get("location") if waypoint else None
        if (
            not isinstance(location, list)
            or len(location) < 2
            or not isinstance(location[0], (int, float))
            or not isinstance(location[1], (int, float))
        ):
            raise RuntimeError("OSM response missing lat/lon")

        lon_value, lat_value = location[0], location[1]

        return LocationPoint(
            lat=lat_value, lon=lon_value, timestamp=datetime.now(timezone.utc)
        )
