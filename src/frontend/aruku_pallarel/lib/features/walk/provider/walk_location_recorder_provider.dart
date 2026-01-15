import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locus/locus.dart' as locus;
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  static const int _maxBufferSize = 64;

  StreamSubscription<locus.Location>? _subscription;
  final List<_LocationPoint> _buffer = [];
  bool _flushInProgress = false;
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
    state = state.copyWith(isRecording: true, errorMessage: null);

    _subscription = locus.Locus.location.stream.listen(
      (location) {
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
        if (_buffer.length >= _maxBufferSize) {
          unawaited(_flushBuffer());
        }
      },
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      },
    );
  }

  Future<void> stopRecording({bool flush = true}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (flush) {
      await _flushBuffer();
    }
    _buffer.clear();
    _walkId = null;
    _userId = null;
    state = state.copyWith(isRecording: false, bufferCount: 0);
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
    final batch = List<_LocationPoint>.from(_buffer);
    _buffer.clear();
    state = state.copyWith(bufferCount: _buffer.length);
    try {
      await _writeBatch(userId, walkId, batch);
    } catch (error) {
      _buffer.insertAll(0, batch);
      state = state.copyWith(
        bufferCount: _buffer.length,
        errorMessage: error.toString(),
      );
    } finally {
      _flushInProgress = false;
    }
  }

  Future<void> _writeBatch(
    String userId,
    String walkId,
    List<_LocationPoint> points,
  ) async {
    final firestoreInstance = firestore.FirebaseFirestore.instance;
    final batchRef = firestoreInstance
        .collection('users')
        .doc(userId)
        .collection('walks')
        .doc(walkId)
        .collection('locations')
        .doc();

    final payload = points
        .map(
          (point) => {
            'timestamp': firestore.Timestamp.fromDate(point.timestamp),
            'geo': firestore.GeoPoint(point.latitude, point.longitude),
          },
        )
        .toList();

    await batchRef.set({
      'points': payload,
      'createdAt': firestore.FieldValue.serverTimestamp(),
    });
  }

  void _dispose() {
    _subscription?.cancel();
  }
}
