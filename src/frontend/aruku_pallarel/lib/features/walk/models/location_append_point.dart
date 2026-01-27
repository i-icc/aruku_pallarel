class LocationAppendPoint {
  const LocationAppendPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracyM,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracyM;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'lat': latitude,
      'lon': longitude,
      if (accuracyM != null) 'accuracyM': accuracyM,
    };
  }
}
