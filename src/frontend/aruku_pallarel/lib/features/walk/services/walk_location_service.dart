import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:locus/locus.dart';

import '../models/walk_location.dart';

class WalkLocationService {
  const WalkLocationService();

  Future<WalkLocation> getCurrentLocation() async {
    final position = await Locus.getCurrentPosition();
    return WalkLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: position.timestamp ?? DateTime.now(),
    );
  }

  Stream<WalkLocation> watchLocations({
    double distanceFilterMeters = 20,
  }) {
    final settings = LocationSettings(
      distanceFilter: distanceFilterMeters.round(),
    );
    return Locus.getPositionStream(locationSettings: settings).map(
      (position) => WalkLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        recordedAt: position.timestamp ?? DateTime.now(),
      ),
    );
  }
}

final walkLocationServiceProvider = Provider<WalkLocationService>((ref) {
  return const WalkLocationService();
});
