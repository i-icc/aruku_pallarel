import 'suggestion_request_result.dart';

class LocationAppendResult {
  const LocationAppendResult({
    required this.locationResult,
    required this.suggestion,
  });

  final String locationResult;
  final SuggestionRequestResult suggestion;

  bool get isOk => locationResult == 'ok';

  factory LocationAppendResult.fromJson(Map<String, dynamic> json) {
    final suggestionPayload = json['suggestion'];
    return LocationAppendResult(
      locationResult: json['locationResult'] as String? ?? 'ng',
      suggestion: suggestionPayload is Map<String, dynamic>
          ? SuggestionRequestResult.fromJson(suggestionPayload)
          : const SuggestionRequestResult(result: 'ng'),
    );
  }
}
