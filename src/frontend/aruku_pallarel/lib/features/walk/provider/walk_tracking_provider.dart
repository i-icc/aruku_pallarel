import 'package:locus/locus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'walk_tracking_provider.g.dart';

class WalkTrackingState {
  const WalkTrackingState({
    this.permissionGranted = false,
    this.isTracking = false,
    this.isRequesting = false,
    this.errorMessage,
  });

  final bool permissionGranted;
  final bool isTracking;
  final bool isRequesting;
  final String? errorMessage;

  WalkTrackingState copyWith({
    bool? permissionGranted,
    bool? isTracking,
    bool? isRequesting,
    String? errorMessage,
  }) {
    return WalkTrackingState(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isTracking: isTracking ?? this.isTracking,
      isRequesting: isRequesting ?? this.isRequesting,
      errorMessage: errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class WalkTrackingNotifier extends _$WalkTrackingNotifier {
  static const double _distanceFilterMeters = 10;
  bool _ready = false;

  @override
  WalkTrackingState build() => const WalkTrackingState();

  Future<bool> startTracking() async {
    if (state.isTracking) {
      return true;
    }

    state = state.copyWith(isRequesting: true, errorMessage: null);

    try {
      final granted = await Locus.requestPermission();
      if (!granted) {
        state = state.copyWith(
          permissionGranted: false,
          isTracking: false,
          isRequesting: false,
        );
        return false;
      }

      if (!_ready) {
        await Locus.ready(
          ConfigPresets.balanced.copyWith(
            distanceFilter: _distanceFilterMeters,
            notification: const NotificationConfig(
              title: 'Walk tracking',
              text: 'Tracking location in the background',
            ),
          ),
        );
        _ready = true;
      }

      await Locus.start();
      state = state.copyWith(
        permissionGranted: true,
        isTracking: true,
        isRequesting: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isTracking: false,
        isRequesting: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<void> stopTracking() async {
    if (!state.isTracking) {
      return;
    }
    try {
      await Locus.stop();
    } finally {
      state = state.copyWith(isTracking: false);
    }
  }
}
