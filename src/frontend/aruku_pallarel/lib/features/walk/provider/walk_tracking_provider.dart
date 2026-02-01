import 'dart:io';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/location_service.dart';

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

  @override
  WalkTrackingState build() {
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

      final locationService = ref.read(locationServiceProvider);
      final serviceEnabled = await locationService.ensureServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          permissionGranted: true,
          isTracking: false,
          isRequesting: false,
          serviceEnabled: false,
        );
        await _refreshDebugState();
        return false;
      }

      await locationService.configure(
        distanceFilterMeters: _distanceFilterMeters,
        accuracy: LocationAccuracy.balanced,
      );
      var backgroundEnabled = false;
      if (Platform.isIOS) {
        backgroundEnabled =
            await locationService.enableBackgroundMode(enable: true);
      }

      state = state.copyWith(
        permissionGranted: true,
        isTracking: true,
        isRequesting: false,
        backgroundSyncEnabled: backgroundEnabled,
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
    String? errorMessage;
    try {
      if (Platform.isIOS) {
        try {
          await ref
              .read(locationServiceProvider)
              .enableBackgroundMode(enable: false);
        } catch (error) {
          errorMessage ??= 'background mode stop failed: $error';
        }
      }
    } finally {
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
      final locationService = ref.read(locationServiceProvider);
      final serviceEnabled = await locationService.isServiceEnabled();
      final status = await locationService.permissionStatus();
      final location = locationService.lastLocation;
      final lat = location?.latitude;
      final lon = location?.longitude;
      final hasLocation = lat != null && lon != null;
      final locationText = hasLocation
          ? '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}'
          : null;
      state = state.copyWith(
        debugState: 'service=${serviceEnabled ? 'on' : 'off'}, '
            'permission=$status, '
            'location=${locationText ?? 'none'}',
        serviceEnabled: serviceEnabled,
        isMoving: null,
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
