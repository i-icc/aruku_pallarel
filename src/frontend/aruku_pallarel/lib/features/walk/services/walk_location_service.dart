import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:locus/locus.dart';

import '../models/walk_location.dart';

class WalkLocationService {
  const WalkLocationService();

  Future<WalkLocation> getCurrentLocation() async {
    final dynamic locus = Locus;
    final dynamic position = await locus.getCurrentPosition();
    return WalkLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: position.timestamp ?? DateTime.now(),
    );
  }

  Stream<WalkLocation> watchLocations({
    double distanceFilterMeters = 20,
  }) {
    final dynamic locus = Locus;
    final dynamic stream = locus.getPositionStream(
      distanceFilter: distanceFilterMeters.round(),
    );
    return (stream as Stream<dynamic>).map(
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
