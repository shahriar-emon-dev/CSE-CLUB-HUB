class UserProfile {
  final String id;
  final String fullName;
  final String? studentId;
  final String? department;
  final String? batch;
  final String? semester;
  final String? group;
  final String email;
  final String? phone;
  final String? bio;
  final String? avatarUrl;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final List<String> skills;
  final UserRole role;
  final String status;
  final bool isApproved;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final String? managedClubId;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.studentId,
    this.department,
    this.batch,
    this.semester,
    this.group,
    required this.email,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.githubUrl,
    this.linkedinUrl,
    this.portfolioUrl,
    this.skills = const [],
    required this.role,
    required this.status,
    required this.isApproved,
    required this.joinedAt,
    required this.updatedAt,
    this.managedClubId,
  });

  bool get isAdmin => role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isExecutive => role == UserRole.executive;
  bool get isMember => role == UserRole.member;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      studentId: json['student_id'] as String?,
      department: json['department'] as String?,
      batch: json['batch'] as String?,
      semester: json['semester'] as String?,
      group: json['group'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      githubUrl: json['github_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      role: UserRole.fromString(json['role'] as String? ?? 'Regular Student'),
      status: json['status'] as String? ?? 'active',
      isApproved: json['is_approved'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      managedClubId: json['managed_club_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'student_id': studentId,
    'department': department,
    'batch': batch,
    'semester': semester,
    'group': group,
    'email': email,
    'phone': phone,
    'bio': bio,
    'avatar_url': avatarUrl,
    'github_url': githubUrl,
    'linkedin_url': linkedinUrl,
    'portfolio_url': portfolioUrl,
    'skills': skills,
    'role': role.value,
    'status': status,
    'is_approved': isApproved,
    'managed_club_id': managedClubId,
  };

  UserProfile copyWith({
    String? fullName,
    String? studentId,
    String? department,
    String? batch,
    String? semester,
    String? group,
    String? phone,
    String? bio,
    String? avatarUrl,
    String? githubUrl,
    String? linkedinUrl,
    String? portfolioUrl,
    List<String>? skills,
    UserRole? role,
    String? status,
    bool? isApproved,
    String? managedClubId,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      batch: batch ?? this.batch,
      semester: semester ?? this.semester,
      group: group ?? this.group,
      email: email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      skills: skills ?? this.skills,
      role: role ?? this.role,
      status: status ?? this.status,
      isApproved: isApproved ?? this.isApproved,
      joinedAt: joinedAt,
      updatedAt: DateTime.now(),
      managedClubId: managedClubId ?? this.managedClubId,
    );
  }
}

enum UserRole {
  superAdmin('Super Admin'),
  executive('Club Executive'),
  member('Regular Student');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    final lower = value.toLowerCase().trim();
    if (lower == 'super admin' || lower == 'super_admin' || lower == 'advisor/admin' || lower == 'admin') return UserRole.superAdmin;
    if (lower == 'club executive' || lower == 'executive') return UserRole.executive;
    return UserRole.member;
  }

  String get displayName {
    switch (this) {
      case UserRole.superAdmin: return 'Super Admin';
      case UserRole.executive: return 'Club Executive';
      case UserRole.member: return 'Regular Student';
    }
  }
}
