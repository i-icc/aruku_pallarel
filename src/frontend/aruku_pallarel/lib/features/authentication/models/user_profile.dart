class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    this.email,
    this.totalWalks = 0,
    this.totalDistanceKm = 0,
  });

  final String userId;
  final String nickname;
  final String? email;
  final int totalWalks;
  final double totalDistanceKm;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final totalDistance = json['totalDistanceKm'];
    return UserProfile(
      userId: json['userId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String?,
      totalWalks: json['totalWalks'] as int? ?? 0,
      totalDistanceKm: (totalDistance is num) ? totalDistance.toDouble() : 0,
    );
  }
}
