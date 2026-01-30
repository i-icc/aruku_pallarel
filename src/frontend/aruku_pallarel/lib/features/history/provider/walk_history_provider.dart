import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'walk_history_provider.g.dart';

class WalkHistoryItem {
  const WalkHistoryItem({
    required this.walkId,
    required this.status,
    this.startedAt,
    this.finishedAt,
    this.startLocation,
  });

  final String walkId;
  final String status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final LatLng? startLocation;
}

class _BatchPoints {
  const _BatchPoints({
    required this.index,
    required this.points,
  });

  final int index;
  final List<_TimedPoint> points;
}

class _TimedPoint {
  const _TimedPoint({
    required this.position,
    this.timestamp,
  });

  final LatLng position;
  final DateTime? timestamp;
}

@Riverpod(keepAlive: true)
class WalkHistoryListNotifier extends _$WalkHistoryListNotifier {
  @override
  Future<List<WalkHistoryItem>> build() async {
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<WalkHistoryItem>> _fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('walks')
        .orderBy('startedAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => WalkHistoryItem(
            walkId: doc.id,
            status: doc.data()['status'] as String? ?? 'unknown',
            startedAt: _toDateTime(doc.data()['startedAt']),
            finishedAt: _toDateTime(doc.data()['finishedAt']),
            startLocation: _parseStartLocation(doc.data()['startLocation']),
          ),
        )
        .toList();
  }

  DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  LatLng? _parseStartLocation(Object? rawLocation) {
    if (rawLocation is! GeoPoint) {
      return null;
    }
    final lat = rawLocation.latitude;
    final lon = rawLocation.longitude;
    if (!_isValidCoordinate(lat, lon)) {
      return null;
    }
    return LatLng(lat, lon);
  }

  bool _isValidCoordinate(double lat, double lon) {
    if (!lat.isFinite || !lon.isFinite) {
      return false;
    }
    if (lat < -90 || lat > 90) {
      return false;
    }
    if (lon < -180 || lon > 180) {
      return false;
    }
    return true;
  }
}

@Riverpod(keepAlive: true)
class WalkHistoryRouteNotifier extends _$WalkHistoryRouteNotifier {
  @override
  Future<List<LatLng>> build(String walkId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final walkRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('walks')
        .doc(walkId);

    final walkSnapshot = await walkRef.get();
    final startLocation = _parseStartLocation(
      walkSnapshot.data()?['startLocation'],
    );

    final snapshot = await walkRef.collection('locations').get();

    final batches = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final indexValue = data['index'];
          final index = indexValue is int
              ? indexValue
              : int.tryParse(doc.id) ?? 0;
          final points = _parsePoints(data['points']);
          return _BatchPoints(index: index, points: points);
        })
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final result = <LatLng>[];
    for (final batch in batches) {
      final points = batch.points.toList()
        ..sort((a, b) {
          final aTime = a.timestamp;
          final bTime = b.timestamp;
          if (aTime == null && bTime == null) {
            return 0;
          }
          if (aTime == null) {
            return -1;
          }
          if (bTime == null) {
            return 1;
          }
          return aTime.compareTo(bTime);
        });
      result.addAll(points.map((point) => point.position));
    }

    if (startLocation != null) {
      if (result.isEmpty || !_isSamePoint(result.first, startLocation)) {
        result.insert(0, startLocation);
      }
    }

    return result;
  }

  bool _isSamePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  bool _isValidCoordinate(double lat, double lon) {
    if (!lat.isFinite || !lon.isFinite) {
      return false;
    }
    if (lat < -90 || lat > 90) {
      return false;
    }
    if (lon < -180 || lon > 180) {
      return false;
    }
    return true;
  }

  LatLng? _parseStartLocation(Object? rawLocation) {
    if (rawLocation is! GeoPoint) {
      return null;
    }
    final lat = rawLocation.latitude;
    final lon = rawLocation.longitude;
    if (!_isValidCoordinate(lat, lon)) {
      return null;
    }
    return LatLng(lat, lon);
  }

  List<_TimedPoint> _parsePoints(Object? rawPoints) {
    if (rawPoints is! List) {
      return const [];
    }
    final result = <_TimedPoint>[];
    for (final rawPoint in rawPoints) {
      if (rawPoint is! Map) {
        continue;
      }
      final geo = rawPoint['geo'];
      if (geo is! GeoPoint) {
        continue;
      }
      final lat = geo.latitude;
      final lon = geo.longitude;
      if (!_isValidCoordinate(lat, lon)) {
        continue;
      }
      final timestamp = rawPoint['timestamp'];
      DateTime? time;
      if (timestamp is Timestamp) {
        time = timestamp.toDate();
      } else if (timestamp is DateTime) {
        time = timestamp;
      }
      result.add(
        _TimedPoint(
          position: LatLng(lat, lon),
          timestamp: time,
        ),
      );
    }
    return result;
  }
}
