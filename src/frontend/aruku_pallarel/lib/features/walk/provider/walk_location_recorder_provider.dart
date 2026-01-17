import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_spoof_provider.dart';

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
  Future<void>? _flushFuture;
  bool _batchLoaded = false;
  int _currentBatchIndex = 1;
  int _currentBatchCount = 0;
  String? _walkId;
  String? _userId;

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
        _buffer.add(
          _LocationPoint(
            timestamp: location.timestamp,
            latitude: coords.latitude,
            longitude: coords.longitude,
          ),
        );
        state = state.copyWith(bufferCount: _buffer.length);
        _requestFlush();
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
    _buffer.add(
      _LocationPoint(
        timestamp: DateTime.now(),
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
    state = state.copyWith(bufferCount: _buffer.length);
    _requestFlush();
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
    _walkId = null;
    _userId = null;
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

  Future<void> _flushBuffer() async {
    if (_flushInProgress || _buffer.isEmpty) {
      return;
    }
    final walkId = _walkId;
    final userId = _userId;
    if (walkId == null || userId == null) {
      return;
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
}
