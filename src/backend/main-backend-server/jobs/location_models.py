from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class LocationPoint:
    lat: float
    lon: float
    timestamp: datetime
