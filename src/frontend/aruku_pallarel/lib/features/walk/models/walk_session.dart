class WalkSession {
  const WalkSession({
    required this.walkId,
    required this.status,
    this.startedAt,
    this.finishedAt,
  });

  final String walkId;
  final String status;
  final String? startedAt;
  final String? finishedAt;

  factory WalkSession.fromJson(Map<String, dynamic> json) {
    return WalkSession(
      walkId: json['walkId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startedAt: json['startedAt'] as String?,
      finishedAt: json['finishedAt'] as String?,
    );
  }
}
