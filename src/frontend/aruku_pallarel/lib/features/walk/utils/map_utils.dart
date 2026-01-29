import 'dart:math';
import 'package:latlong2/latlong.dart';

class MapUtils {
  static double degreesToRadians(double degrees) => degrees * (pi / 180.0);

  static double? calculateRouteDistanceKm(List<LatLng> points) {
    if (points.length < 2) {
      return null;
    }
    const earthRadius = 6371000.0; // meters
    double totalMeters = 0;
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dLat = degreesToRadians(p2.latitude - p1.latitude);
      final dLon = degreesToRadians(p2.longitude - p1.longitude);
      final lat1Rad = degreesToRadians(p1.latitude);
      final lat2Rad = degreesToRadians(p2.latitude);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * asin(sqrt(a));
      totalMeters += earthRadius * c;
    }
    if (totalMeters <= 0) {
      return null;
    }
    return totalMeters / 1000.0;
  }

  static bool isSamePoint(LatLng a, LatLng b, {double threshold = 0.000001}) {
    return (a.latitude - b.latitude).abs() < threshold &&
        (a.longitude - b.longitude).abs() < threshold;
  }
}
