enum AppUserRole {
  student,
  executive,
  admin,
}

extension AppUserRoleX on AppUserRole {
  String get value {
    switch (this) {
      case AppUserRole.student:
        return 'student';
      case AppUserRole.executive:
        return 'executive';
      case AppUserRole.admin:
        return 'admin';
    }
  }

  static AppUserRole fromValue(String raw) {
    switch (raw.toLowerCase()) {
      case 'admin':
        return AppUserRole.admin;
      case 'executive':
        return AppUserRole.executive;
      default:
        return AppUserRole.student;
    }
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.roleRequest,
    this.fullName,
    this.studentId,
    this.batch,
    this.section,
    this.createdAt,
  });

  final String id;
  final String email;
  final AppUserRole role;
  final bool roleRequest;
  final String? fullName;
  final String? studentId;
  final String? batch;
  final String? section;
  final DateTime? createdAt;

  bool get isComplete {
    final hasName = fullName != null && fullName!.trim().isNotEmpty;
    final hasStudentId = studentId != null && studentId!.trim().isNotEmpty;
    final hasBatch = batch != null && batch!.trim().isNotEmpty;
    final hasSection = section != null && section!.trim().isNotEmpty;
    return hasName && hasStudentId && hasBatch && hasSection;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      role: AppUserRoleX.fromValue((map['role'] as String?) ?? 'student'),
      roleRequest: (map['role_request'] as bool?) ?? false,
      fullName: map['full_name'] as String?,
      studentId: map['student_id'] as String?,
      batch: map['batch'] as String?,
      section: map['section'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
