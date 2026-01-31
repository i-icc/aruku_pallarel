import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:locus/locus.dart' as locus;
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../env/env.dart';

part 'walk_tracking_provider.g.dart';

class WalkTrackingState {
  const WalkTrackingState({
    this.permissionGranted = false,
    this.isTracking = false,
    this.isRequesting = false,
    this.errorMessage,
    this.debugState,
    this.serviceEnabled,
    this.isMoving,
    this.hasLocation = false,
    this.locationText,
    this.whenInUseGranted,
    this.alwaysGranted,
    this.backgroundSyncEnabled = false,
  });

  final bool permissionGranted;
  final bool isTracking;
  final bool isRequesting;
  final String? errorMessage;
  final String? debugState;
  final bool? serviceEnabled;
  final bool? isMoving;
  final bool hasLocation;
  final String? locationText;
  final bool? whenInUseGranted;
  final bool? alwaysGranted;
  final bool backgroundSyncEnabled;

  WalkTrackingState copyWith({
    bool? permissionGranted,
    bool? isTracking,
    bool? isRequesting,
    String? errorMessage,
    String? debugState,
    bool? serviceEnabled,
    bool? isMoving,
    bool? hasLocation,
    String? locationText,
    bool? whenInUseGranted,
    bool? alwaysGranted,
    bool? backgroundSyncEnabled,
  }) {
    return WalkTrackingState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isTracking: isTracking ?? this.isTracking,
      isRequesting: isRequesting ?? this.isRequesting,
      errorMessage: errorMessage,
      debugState: debugState ?? this.debugState,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      isMoving: isMoving ?? this.isMoving,
      hasLocation: hasLocation ?? this.hasLocation,
      locationText: locationText ?? this.locationText,
      whenInUseGranted: whenInUseGranted ?? this.whenInUseGranted,
      alwaysGranted: alwaysGranted ?? this.alwaysGranted,
      backgroundSyncEnabled:
          backgroundSyncEnabled ?? this.backgroundSyncEnabled,
    );
  }
}

@Riverpod(keepAlive: true)
class WalkTrackingNotifier extends _$WalkTrackingNotifier {
  static const double _distanceFilterMeters = 15;
  static const int _syncMaxBatchSize = 50;
  static const int _syncThreshold = 10;
  bool _ready = false;
  StreamSubscription<User?>? _tokenSubscription;
  String? _syncWalkId;
  String? _lastSyncToken;

  @override
  WalkTrackingState build() {
    ref.onDispose(() {
      _tokenSubscription?.cancel();
    });
    return const WalkTrackingState();
  }

  Future<bool> startTracking({String? walkId}) async {
    if (state.isTracking) {
      if (walkId != null && walkId.isNotEmpty) {
        await _configureBackgroundSync(walkId);
      }
      return true;
    }

    state = state.copyWith(isRequesting: true, errorMessage: null);

    try {
      final granted = await _requestLocationPermissions();
      if (!granted) {
        state = state.copyWith(
          permissionGranted: false,
          isTracking: false,
          isRequesting: false,
        );
        await _refreshDebugState();
        return false;
      }

      if (!_ready) {
        await locus.Locus.ready(
          locus.ConfigPresets.balanced.copyWith(
            distanceFilter: _distanceFilterMeters,
            autoSync: false,
            batchSync: false,
            stopOnTerminate: false,
            enableHeadless: true,
            persistMode: locus.PersistMode.location,
            maxDaysToPersist: 7,
            maxRecordsToPersist: 200,
            notification: const locus.NotificationConfig(
              title: 'Walk tracking',
              text: 'Tracking location in the background',
            ),
          ),
        );
        _ready = true;
      }

      await locus.Locus.start();
      state = state.copyWith(
        permissionGranted: true,
        isTracking: true,
        isRequesting: false,
      );
      if (walkId != null && walkId.isNotEmpty) {
        await _configureBackgroundSync(walkId);
      } else {
        state = state.copyWith(backgroundSyncEnabled: false);
      }
      await _refreshDebugState();
      return true;
    } catch (error) {
      state = state.copyWith(
        isTracking: false,
        isRequesting: false,
        errorMessage: error.toString(),
      );
      await _refreshDebugState();
      return false;
    }
  }

  Future<void> stopTracking() async {
    if (!state.isTracking) {
      return;
    }
    String? errorMessage;
    try {
      if (Platform.isIOS) {
        try {
          await locus.Locus.dataSync.pause();
        } catch (error) {
          errorMessage ??= 'dataSync pause failed: $error';
        }
      }
      try {
        await locus.Locus.stop();
      } catch (error) {
        errorMessage ??= 'stop failed: $error';
      }
    } finally {
      _syncWalkId = null;
      _lastSyncToken = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      state = state.copyWith(
        isTracking: false,
        backgroundSyncEnabled: false,
        errorMessage: errorMessage,
      );
      await _refreshDebugState();
    }
  }

  Future<void> refreshDebugState() async {
    await _refreshDebugState();
  }

  Future<bool> _requestLocationPermissions() async {
    final whenInUse = await permission.Permission.locationWhenInUse.request();
    final whenInUseGranted = whenInUse.isGranted;
    if (!whenInUseGranted) {
      state = state.copyWith(
        permissionGranted: false,
        whenInUseGranted: false,
      );
      return false;
    }

    final always = await permission.Permission.locationAlways.request();
    final alwaysGranted = always.isGranted;
    state = state.copyWith(
      permissionGranted: true,
      whenInUseGranted: true,
      alwaysGranted: alwaysGranted,
    );
    return true;
  }

  Future<void> _refreshDebugState() async {
    try {
      final serviceStatus = await permission.Permission.location.serviceStatus;
      final serviceEnabled =
          serviceStatus == permission.ServiceStatus.enabled;
      final debug = await locus.Locus.getState();
      final location = debug.location;
      final hasLocation = location != null && location.coords.isValid;
      final locationText = hasLocation
          ? '${location.coords.latitude.toStringAsFixed(5)},'
              '${location.coords.longitude.toStringAsFixed(5)}'
          : null;
      state = state.copyWith(
        debugState: 'service=${serviceEnabled ? 'on' : 'off'}, '
            'enabled=${debug.enabled}, '
            'isMoving=${debug.isMoving}, '
            'location=${locationText ?? 'none'}',
        serviceEnabled: serviceEnabled,
        isMoving: debug.isMoving,
        hasLocation: hasLocation,
        locationText: locationText,
      );
    } catch (error) {
      state = state.copyWith(
        debugState: 'state error: $error',
        serviceEnabled: null,
        isMoving: null,
        hasLocation: false,
        locationText: null,
      );
    }
  }

  Future<void> _configureBackgroundSync(String walkId) async {
    if (!Platform.isIOS) {
      state = state.copyWith(backgroundSyncEnabled: false);
      return;
    }
    _syncWalkId = walkId;
    await _applySyncConfig(force: true);
    _startTokenListener();
    await locus.Locus.dataSync.resume();
    state = state.copyWith(backgroundSyncEnabled: true);
  }

  void _startTokenListener() {
    if (_tokenSubscription != null) {
      return;
    }
    _tokenSubscription =
        FirebaseAuth.instance.idTokenChanges().listen((_) async {
      if (_syncWalkId == null) {
        return;
      }
      await _applySyncConfig();
      await locus.Locus.dataSync.resume();
    });
  }

  Future<void> _applySyncConfig({bool force = false}) async {
    final walkId = _syncWalkId;
    if (walkId == null || walkId.isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    String? token;
    try {
      token = await user.getIdToken();
    } catch (_) {
      return;
    }
    if (token == null || token.isEmpty) {
      return;
    }
    if (!force && token == _lastSyncToken) {
      return;
    }
    _lastSyncToken = token;
    final ingestUrl = _buildIngestUrl(walkId);
    await locus.Locus.setConfig(
      locus.Config(
        url: ingestUrl,
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
        },
        autoSync: true,
        batchSync: true,
        maxBatchSize: _syncMaxBatchSize,
        autoSyncThreshold: _syncThreshold,
      ),
    );
  }

  String _buildIngestUrl(String walkId) {
    final base = Env.backendBaseUrl;
    final normalized =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$normalized/v1/walks/$walkId/locations:ingest';
  }
}
