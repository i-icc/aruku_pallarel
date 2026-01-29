import 'dart:math';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';


class RouteSmoother {
  static const int defaultSplineSteps = 8;
  static const double defaultSplineAlpha = 0.5;

  static List<LatLng> smooth(
    List<LatLng> points, {
    int steps = defaultSplineSteps,
    double alpha = defaultSplineAlpha,
  }) {
    if (points.length < 2) {
      return List<LatLng>.from(points);
    }
    final smoothed = <LatLng>[];
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];
      final segment = _catmullRomSegment(p0, p1, p2, p3, steps, alpha);
      if (smoothed.isNotEmpty && segment.isNotEmpty) {
        segment.removeAt(0);
      }
      smoothed.addAll(segment);
    }
    return smoothed;
  }

  static List<LatLng> _catmullRomSegment(
    LatLng p0,
    LatLng p1,
    LatLng p2,
    LatLng p3,
    int steps,
    double alpha,
  ) {
    final t0 = 0.0;
    final t1 = _catmullT(t0, p0, p1, alpha);
    final t2 = _catmullT(t1, p1, p2, alpha);
    final t3 = _catmullT(t2, p2, p3, alpha);
    final segment = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = ui.lerpDouble(t1, t2, i / steps) ?? t1;
      segment.add(_catmullRomPoint(p0, p1, p2, p3, t0, t1, t2, t3, t));
    }
    return segment;
  }

  static double _catmullT(double t, LatLng p0, LatLng p1, double alpha) {
    final dx = p1.latitude - p0.latitude;
    final dy = p1.longitude - p0.longitude;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) {
      return t + 0.000001;
    }
    return t + pow(dist, alpha).toDouble();
  }

  static LatLng _catmullRomPoint(
    LatLng p0,
    LatLng p1,
    LatLng p2,
    LatLng p3,
    double t0,
    double t1,
    double t2,
    double t3,
    double t,
  ) {
    final a1 = _interpolateLatLng(p0, p1, t0, t1, t);
    final a2 = _interpolateLatLng(p1, p2, t1, t2, t);
    final a3 = _interpolateLatLng(p2, p3, t2, t3, t);
    final b1 = _interpolateLatLng(a1, a2, t0, t2, t);
    final b2 = _interpolateLatLng(a2, a3, t1, t3, t);
    return _interpolateLatLng(b1, b2, t1, t2, t);
  }

  static LatLng _interpolateLatLng(
    LatLng start,
    LatLng end,
    double t0,
    double t1,
    double t,
  ) {
    final span = t1 - t0;
    if (span.abs() < 0.000001) {
      return start;
    }
    return lerpLatLng(start, end, (t - t0) / span);
  }

  static LatLng lerpLatLng(LatLng start, LatLng target, double t) {
    final lat =
        ui.lerpDouble(start.latitude, target.latitude, t) ?? target.latitude;
    final lng =
        ui.lerpDouble(start.longitude, target.longitude, t) ?? target.longitude;
    return LatLng(lat, lng);
  }
}
