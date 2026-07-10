class ClubExecutive {
  final String id;
  final String clubId;
  final String userId;
  final String roleTitle;
  final String position;
  final String fullName;
  final String? avatarUrl;
  final String? clubName;
  final String? studentId;
  final String? department;
  final String? batch;
  final String? email;
  final String? contact;
  final DateTime? assignedDate;
  final bool isActive;

  const ClubExecutive({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.roleTitle,
    required this.position,
    required this.fullName,
    this.avatarUrl,
    this.clubName,
    this.studentId,
    this.department,
    this.batch,
    this.email,
    this.contact,
    this.assignedDate,
    this.isActive = true,
  });

  factory ClubExecutive.fromJson(Map<String, dynamic> json) {
    final rawDate = json['assigned_date'] ?? json['created_at'];
    return ClubExecutive(
      id: json['id'] as String? ?? '',
      clubId: json['club_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      roleTitle: json['role_title'] as String? ?? json['position'] as String? ?? 'Executive',
      position: json['position'] as String? ?? json['role_title'] as String? ?? 'Executive',
      fullName: json['full_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      clubName: json['club_name'] as String?,
      studentId: json['student_id'] as String?,
      department: json['department'] as String?,
      batch: json['batch'] as String?,
      email: json['email'] as String?,
      contact: json['contact'] as String? ?? json['phone'] as String?,
      assignedDate: rawDate != null ? DateTime.tryParse(rawDate.toString()) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
