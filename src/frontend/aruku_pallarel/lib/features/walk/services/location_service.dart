import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:location/location.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  final Location _location = Location();
  LocationData? _lastLocation;

  LocationData? get lastLocation => _lastLocation;

  Stream<LocationData> get stream {
    return _location.onLocationChanged.map((data) {
      _lastLocation = data;
      return data;
    });
  }

  Future<bool> ensureServiceEnabled() async {
    var enabled = await _location.serviceEnabled();
    if (!enabled) {
      enabled = await _location.requestService();
    }
    return enabled;
  }

  Future<PermissionStatus> ensurePermission() async {
    var status = await _location.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
    }
    return status;
  }

  Future<void> configure({
    required double distanceFilterMeters,
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int? intervalMs,
  }) async {
    if (intervalMs == null) {
      await _location.changeSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      );
      return;
    }
    await _location.changeSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
      interval: intervalMs,
    );
  }

  Future<bool> enableBackgroundMode({required bool enable}) async {
    try {
      return await _location.enableBackgroundMode(enable: enable);
    } catch (_) {
      return false;
    }
  }

  Future<LocationData?> getCurrent({Duration? timeout}) async {
    try {
      final future = _location.getLocation();
      if (timeout == null) {
        return await future;
      }
      return await future.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isServiceEnabled() async {
    return _location.serviceEnabled();
  }

  Future<PermissionStatus> permissionStatus() async {
    return _location.hasPermission();
  }
}
