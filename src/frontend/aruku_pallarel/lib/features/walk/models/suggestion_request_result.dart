class SuggestionRequestResult {
  const SuggestionRequestResult({
    required this.result,
    this.requestId,
  });

  final String result;
  final String? requestId;

  bool get isOk => result == 'ok';

  factory SuggestionRequestResult.fromJson(Map<String, dynamic> json) {
    return SuggestionRequestResult(
      result: json['result'] as String? ?? 'ng',
      requestId: json['requestId'] as String?,
    );
  }
}
