class ClubExecutive {
  final String id;
  final String clubId;
  final String userId;
  final String roleTitle;
  final String fullName;
  final String? avatarUrl;

  const ClubExecutive({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.roleTitle,
    required this.fullName,
    this.avatarUrl,
  });

  factory ClubExecutive.fromJson(Map<String, dynamic> json) {
    return ClubExecutive(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      roleTitle: json['role_title'] as String? ?? 'Executive',
      fullName: json['full_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
