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
        url = f"{self._base_url.rstrip('/')}/nearest"
        payload = json.dumps({"lat": lat, "lon": lon}).encode("utf-8")
        request_obj = urllib.request.Request(
            url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

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

        lat_value = data.get("lat")
        lon_value = data.get("lon")
        if not isinstance(lat_value, (int, float)) or not isinstance(
            lon_value, (int, float)
        ):
            raise RuntimeError("OSM response missing lat/lon")

        return LocationPoint(
            lat=lat_value, lon=lon_value, timestamp=datetime.now(timezone.utc)
        )
