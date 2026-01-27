import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:locus/locus.dart' as locus;
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../env/env.dart';
import '../services/location_sync_context.dart';

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
    );
  }
}

@Riverpod(keepAlive: true)
class WalkTrackingNotifier extends _$WalkTrackingNotifier {
  static const double _distanceFilterMeters = 15;
  static const int _syncBatchSize = 64;
  static const int _syncThreshold = 10;
  bool _ready = false;

  StreamSubscription<User?>? _authSub;

  @override
  WalkTrackingState build() {
    ref.onDispose(_dispose);
    return const WalkTrackingState();
  }

  Future<bool> startTracking() async {
    if (state.isTracking) {
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
            url: '${Env.backendBaseUrl}/v1/locations:sync',
            method: 'POST',
            autoSync: true,
            batchSync: true,
            maxBatchSize: _syncBatchSize,
            autoSyncThreshold: _syncThreshold,
            httpTimeout: 20,
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
        await locus.Locus.dataSync
            .setSyncBodyBuilder(buildForegroundLocationSyncBody);
        locus.Locus.setHeadersCallback(() async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return {};
          }
          try {
            final token = await user.getIdToken();
            if (token == null || token.isEmpty) {
              return {};
            }
            return {'Authorization': 'Bearer $token'};
          } catch (_) {
            return {};
          }
        });
        await locus.Locus.refreshHeaders();
        _authSub ??= FirebaseAuth.instance.idTokenChanges().listen((_) async {
          try {
            await locus.Locus.refreshHeaders();
          } catch (_) {}
        });
        _ready = true;
      }

      await locus.Locus.start();
      state = state.copyWith(
        permissionGranted: true,
        isTracking: true,
        isRequesting: false,
      );
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
    try {
      await locus.Locus.stop();
    } finally {
      state = state.copyWith(isTracking: false);
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

  void _dispose() {
    _authSub?.cancel();
  }
}
