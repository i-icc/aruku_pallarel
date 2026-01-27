import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_spoof_provider.dart';
import '../infrastructure/walk_api.dart';
import '../models/location_append_point.dart';
import '../../share/services/backend_exception.dart';

part 'walk_location_recorder_provider.g.dart';

class WalkLocationRecorderState {
  const WalkLocationRecorderState({
    this.isRecording = false,
    this.bufferCount = 0,
    this.errorMessage,
  });

  final bool isRecording;
  final int bufferCount;
  final String? errorMessage;

  WalkLocationRecorderState copyWith({
    bool? isRecording,
    int? bufferCount,
    String? errorMessage,
  }) {
    return WalkLocationRecorderState(
      isRecording: isRecording ?? this.isRecording,
      bufferCount: bufferCount ?? this.bufferCount,
      errorMessage: errorMessage,
    );
  }
}

class _LocationPoint {
  const _LocationPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
}

@Riverpod(keepAlive: true)
class WalkLocationRecorderNotifier extends _$WalkLocationRecorderNotifier {
  static const int _maxBatchSize = 64;

  StreamSubscription<locus.Location>? _subscription;
  final List<_LocationPoint> _buffer = [];
  bool _flushInProgress = false;
  bool _flushPending = false;
  Future<bool>? _flushFuture;
  String? _walkId;
  DateTime? _lastRecordedAt;

  @override
  WalkLocationRecorderState build() {
    ref.onDispose(_dispose);
    return const WalkLocationRecorderState();
  }

  Future<void> startRecording(String walkId) async {
    if (_walkId == walkId && state.isRecording) {
      return;
    }

    await stopRecording(flush: true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'User not authenticated.',
      );
      return;
    }

    _walkId = walkId;
    _lastRecordedAt = null;
    state = state.copyWith(isRecording: true, errorMessage: null);

    _subscription = locus.Locus.location.stream.listen(
      (location) {
        if (ref.read(locationSpoofNotifierProvider).enabled) {
          return;
        }
        final coords = location.coords;
        if (!coords.isValid) {
          return;
        }
        _appendLivePoint(
          _LocationPoint(
            timestamp: location.timestamp,
            latitude: coords.latitude,
            longitude: coords.longitude,
          ),
        );
      },
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );
  }

  void recordManualLocation(LatLng location) {
    if (!state.isRecording || _walkId == null) {
      return;
    }
    _appendLivePoint(
      _LocationPoint(
        timestamp: DateTime.now(),
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
  }

  Future<void> stopRecording({bool flush = true}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (flush) {
      if (_flushInProgress && _flushFuture != null) {
        _flushPending = true;
        await _flushFuture;
      } else {
        await _flushBuffer();
      }
    }
    _buffer.clear();
    _walkId = null;
    _lastRecordedAt = null;
    state = state.copyWith(isRecording: false, bufferCount: 0);
  }

  void _requestFlush() {
    if (_flushInProgress) {
      _flushPending = true;
      return;
    }
    _flushFuture = _flushBuffer();
    unawaited(_flushFuture);
  }

  Future<bool> _flushBuffer() async {
    if (_flushInProgress || _buffer.isEmpty) {
      return true;
    }
    final walkId = _walkId;
    if (walkId == null) {
      return false;
    }

    _flushInProgress = true;
    _flushPending = false;
    var success = true;
    try {
      while (_buffer.isNotEmpty) {
        final takeCount =
            _buffer.length > _maxBatchSize ? _maxBatchSize : _buffer.length;
        final chunk = _buffer.take(takeCount).toList();
        _buffer.removeRange(0, takeCount);
        state = state.copyWith(bufferCount: _buffer.length);
        final chunkSuccess = await _sendPoints(
          walkId,
          chunk,
          source: 'foreground',
        );
        if (!chunkSuccess) {
          _buffer.insertAll(0, chunk);
          state = state.copyWith(bufferCount: _buffer.length);
          success = false;
          break;
        }
      }
    } catch (error) {
      state = state.copyWith(
        errorMessage: error.toString(),
      );
      success = false;
    } finally {
      _flushInProgress = false;
      _flushFuture = null;
    }

    if (success && (_buffer.isNotEmpty || _flushPending)) {
      _requestFlush();
    }
    return success;
  }

  void _dispose() {
    _subscription?.cancel();
  }

  void _appendLivePoint(_LocationPoint point) {
    _buffer.add(point);
    _lastRecordedAt = point.timestamp;
    state = state.copyWith(bufferCount: _buffer.length);
    _requestFlush();
  }

  Future<LatLng?> syncStoredLocations({int limit = 200}) async {
    if (!state.isRecording || _walkId == null) {
      return null;
    }
    try {
      final stored = await locus.Locus.location.getLocations(limit: limit);
      if (stored.isEmpty) {
        return null;
      }

      final points = <_LocationPoint>[];
      for (final location in stored) {
        final coords = location.coords;
        if (!coords.isValid) {
          continue;
        }
        final timestamp = location.timestamp;
        final lastRecordedAt = _lastRecordedAt;
        if (lastRecordedAt != null && !timestamp.isAfter(lastRecordedAt)) {
          continue;
        }
        points.add(
          _LocationPoint(
            timestamp: timestamp,
            latitude: coords.latitude,
            longitude: coords.longitude,
          ),
        );
      }

      if (points.isEmpty) {
        await locus.Locus.location.destroyLocations();
        return null;
      }

      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _lastRecordedAt = points.last.timestamp;
      final flushed = await _sendPoints(
        _walkId!,
        points,
        source: 'background',
      );
      if (flushed) {
        await locus.Locus.location.destroyLocations();
      }

      final last = points.last;
      return LatLng(last.latitude, last.longitude);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  Future<bool> _sendPoints(
    String walkId,
    List<_LocationPoint> points, {
    required String source,
  }) async {
    if (points.isEmpty) {
      return true;
    }
    final api = ref.read(walkApiProvider);
    final payload = points
        .map(
          (point) => LocationAppendPoint(
            timestamp: point.timestamp,
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        )
        .toList();
    try {
      final result = await api.appendLocations(
        walkId: walkId,
        points: payload,
        source: source,
      );
      if (!result.isOk) {
        _debugLog('location_append result=${result.locationResult}');
      }
      return result.isOk;
    } on BackendException catch (error) {
      _debugLog('location_append error=${error.code}');
      state = state.copyWith(errorMessage: error.message);
      return false;
    } catch (error) {
      _debugLog('location_append error=$error');
      state = state.copyWith(errorMessage: error.toString());
      return false;
    }
  }
}
