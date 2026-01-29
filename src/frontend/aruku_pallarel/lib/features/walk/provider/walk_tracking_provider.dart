import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

  @override
  WalkTrackingState build() => const WalkTrackingState();

  Future<bool> startTracking(String walkId) async {
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

      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          isTracking: false,
          isRequesting: false,
          errorMessage: 'User not authenticated.',
        );
        return false;
      }
      final token = await user.getIdToken();

      await locus.Locus.ready(
        locus.ConfigPresets.balanced.copyWith(
          url: '${Env.backendBaseUrl}/v1/walks/$walkId/locations',
          headers: {
            'Authorization': 'Bearer $token',
          },
          autoSync: true,
          batchSync: true,
          maxBatchSize: 50,
          distanceFilter: _distanceFilterMeters,
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

  Future<bool> requestPermission() async {
    return await _requestLocationPermissions();
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
}
