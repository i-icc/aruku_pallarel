import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_spoof_provider.dart';
import '../infrastructure/walk_api.dart';
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
  static const Duration _suggestionCooldown = Duration(minutes: 5);
  static const double _suggestionMinDistanceMeters = 250;

  StreamSubscription<locus.Location>? _subscription;
  final List<_LocationPoint> _buffer = [];
  bool _flushInProgress = false;
  bool _flushPending = false;
  Future<bool>? _flushFuture;
  bool _batchLoaded = false;
  int _currentBatchIndex = 1;
  int _currentBatchCount = 0;
  String? _walkId;
  String? _userId;
  DateTime? _lastRecordedAt;
  bool _requestInFlight = false;
  double _distanceSinceRequest = 0;
  DateTime? _lastRequestOkAt;
  _LocationPoint? _lastDistancePoint;

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
    _userId = user.uid;
    _resetSuggestionState();
    _lastRecordedAt = null;
    await _loadLatestBatch(user.uid, walkId);
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
    if (!state.isRecording || _walkId == null || _userId == null) {
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
    _resetBatchState();
    _resetSuggestionState();
    _walkId = null;
    _userId = null;
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
    final userId = _userId;
    if (walkId == null || userId == null) {
      return false;
    }

    _flushInProgress = true;
    _flushPending = false;
    var success = true;
    try {
      if (!_batchLoaded) {
        await _loadLatestBatch(userId, walkId);
      }
      while (_buffer.isNotEmpty) {
        if (_currentBatchCount >= _maxBatchSize) {
          _currentBatchIndex += 1;
          _currentBatchCount = 0;
        }
        final capacity = _maxBatchSize - _currentBatchCount;
        final takeCount =
            _buffer.length > capacity ? capacity : _buffer.length;
        final chunk = _buffer.take(takeCount).toList();
        _buffer.removeRange(0, takeCount);
        state = state.copyWith(bufferCount: _buffer.length);
        final chunkSuccess = await _writeBatchChunk(
          userId,
          walkId,
          _currentBatchIndex,
          _currentBatchCount == 0,
          chunk,
        );
        if (!chunkSuccess) {
          _buffer.insertAll(0, chunk);
          state = state.copyWith(bufferCount: _buffer.length);
          success = false;
          break;
        }
        _currentBatchCount += chunk.length;
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

  Future<bool> _writeBatchChunk(
    String userId,
    String walkId,
    int batchIndex,
    bool isNewBatch,
    List<_LocationPoint> points,
  ) async {
    final firestoreInstance = firestore.FirebaseFirestore.instance;
    final batchRef = firestoreInstance
        .collection('users')
        .doc(userId)
        .collection('walks')
        .doc(walkId)
        .collection('locations')
        .doc(batchIndex.toString());

    final payload = points
        .map(
          (point) => {
            'timestamp': firestore.Timestamp.fromDate(point.timestamp),
            'geo': firestore.GeoPoint(point.latitude, point.longitude),
          },
        )
        .toList();

    final data = <String, Object?>{
      'index': batchIndex,
      'count': firestore.FieldValue.increment(points.length),
      'points': firestore.FieldValue.arrayUnion(payload),
      'updatedAt': firestore.FieldValue.serverTimestamp(),
    };
    if (isNewBatch) {
      data['createdAt'] = firestore.FieldValue.serverTimestamp();
    }
    await batchRef.set(data, firestore.SetOptions(merge: true));
    return true;
  }

  Future<void> _loadLatestBatch(String userId, String walkId) async {
    _batchLoaded = false;
    _currentBatchIndex = 1;
    _currentBatchCount = 0;
    try {
      final snapshot = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('walks')
          .doc(walkId)
          .collection('locations')
          .orderBy('index', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        _batchLoaded = true;
        return;
      }
      final doc = snapshot.docs.first;
      final data = doc.data();
      final indexValue = data['index'];
      final countValue = data['count'];
      final resolvedIndex = indexValue is int
          ? indexValue
          : int.tryParse(doc.id) ?? 1;
      var resolvedCount = 0;
      if (countValue is int) {
        resolvedCount = countValue;
      } else if (data['points'] is List) {
        resolvedCount = (data['points'] as List).length;
      }
      if (resolvedCount >= _maxBatchSize) {
        _currentBatchIndex = resolvedIndex + 1;
        _currentBatchCount = 0;
      } else {
        _currentBatchIndex = resolvedIndex;
        _currentBatchCount = resolvedCount;
      }
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      _batchLoaded = true;
    }
  }

  void _resetBatchState() {
    _batchLoaded = false;
    _currentBatchIndex = 1;
    _currentBatchCount = 0;
  }

  void _dispose() {
    _subscription?.cancel();
  }

  void _resetSuggestionState() {
    _requestInFlight = false;
    _distanceSinceRequest = 0;
    _lastDistancePoint = null;
    _lastRequestOkAt = null;
  }

  void _appendLivePoint(_LocationPoint point) {
    _buffer.add(point);
    _lastRecordedAt = point.timestamp;
    state = state.copyWith(bufferCount: _buffer.length);
    _handleSuggestionTrigger(point);
    _requestFlush();
  }

  Future<LatLng?> syncStoredLocations({int limit = 200}) async {
    if (!state.isRecording || _walkId == null || _userId == null) {
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

      _buffer.addAll(points);
      _lastRecordedAt = points.last.timestamp;
      state = state.copyWith(bufferCount: _buffer.length);
      for (final point in points) {
        _updateDistance(point);
      }

      final flushed = await _flushBuffer();
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

  void _handleSuggestionTrigger(_LocationPoint point) {
    if (!state.isRecording || _walkId == null) {
      return;
    }

    _updateDistance(point);
    _maybeRequestSuggestion(point);
  }

  void _updateDistance(_LocationPoint point) {
    final lastPoint = _lastDistancePoint;
    if (lastPoint == null) {
      _lastDistancePoint = point;
      return;
    }
    _distanceSinceRequest += _haversineDistanceMeters(
      lastPoint.latitude,
      lastPoint.longitude,
      point.latitude,
      point.longitude,
    );
    _lastDistancePoint = point;
  }

  Future<void> _maybeRequestSuggestion(_LocationPoint point) async {
    if (_requestInFlight) {
      return;
    }
    final walkId = _walkId;
    if (walkId == null) {
      return;
    }

    final now = DateTime.now();
    final baseline = _lastRequestOkAt;
    if (baseline != null && now.difference(baseline) < _suggestionCooldown) {
      return;
    }
    if (_distanceSinceRequest < _suggestionMinDistanceMeters) {
      return;
    }

    _requestInFlight = true;
    try {
      await _ensureFlushed();
      _debugLog(
        'suggestion_request send walkId=$walkId distance=${_distanceSinceRequest.toStringAsFixed(1)}m',
      );
      final api = ref.read(walkApiProvider);
      final result = await api.requestSuggestion(walkId);
      _debugLog(
        'suggestion_request result=${result.result} requestId=${result.requestId ?? '-'}',
      );
      if (result.isOk) {
        _lastRequestOkAt = now;
        _distanceSinceRequest = 0;
        _lastDistancePoint = point;
      }
    } on BackendException catch (error) {
      _debugLog('suggestion_request error=${error.code}');
      state = state.copyWith(errorMessage: error.message);
    } catch (error) {
      _debugLog('suggestion_request error=$error');
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _ensureFlushed() async {
    if (_flushInProgress && _flushFuture != null) {
      await _flushFuture;
      return;
    }
    if (_buffer.isNotEmpty) {
      await _flushBuffer();
    }
  }

  double _haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return radius * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);

  void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
