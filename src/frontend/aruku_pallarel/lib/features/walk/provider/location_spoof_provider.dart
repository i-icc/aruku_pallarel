import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_spoof_provider.g.dart';

class LocationSpoofState {
  const LocationSpoofState({
    this.enabled = false,
    this.location,
    this.updatedAt,
  });

  final bool enabled;
  final LatLng? location;
  final DateTime? updatedAt;

  LocationSpoofState copyWith({
    bool? enabled,
    LatLng? location,
    DateTime? updatedAt,
  }) {
    return LocationSpoofState(
      enabled: enabled ?? this.enabled,
      location: location ?? this.location,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
class LocationSpoofNotifier extends _$LocationSpoofNotifier {
  @override
  LocationSpoofState build() => const LocationSpoofState();

  void setEnabled(bool value) {
    if (value == state.enabled) {
      return;
    }
    if (!value) {
      state = const LocationSpoofState();
      return;
    }
    state = state.copyWith(enabled: true);
  }

  void setLocation(LatLng location) {
    if (!state.enabled) {
      return;
    }
    state = state.copyWith(location: location, updatedAt: DateTime.now());
  }

  void clear() {
    if (state.location == null && state.updatedAt == null) {
      return;
    }
    state = LocationSpoofState(enabled: state.enabled);
  }
}
