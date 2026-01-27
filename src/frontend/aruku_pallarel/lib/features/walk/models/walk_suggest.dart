import 'package:latlong2/latlong.dart';

class WalkSuggest {
  const WalkSuggest({
    required this.suggestId,
    required this.position,
    this.messageId,
    this.suggestedAt,
  });

  final String suggestId;
  final LatLng position;
  final String? messageId;
  final DateTime? suggestedAt;
}
