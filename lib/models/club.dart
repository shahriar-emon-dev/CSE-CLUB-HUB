class Club {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final String? logoUrl;
  final String? coverImageUrl;
  final List<String> categories;
  final String? meetingSchedule;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // From club_list_view
  final int memberCount;

  const Club({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconName,
    this.colorHex,
    this.logoUrl,
    this.coverImageUrl,
    this.categories = const [],
    this.meetingSchedule,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      meetingSchedule: json['meeting_schedule'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'icon_name': iconName,
    'color_hex': colorHex,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'categories': categories,
    'meeting_schedule': meetingSchedule,
    'location': location,
  };
}

class ClubMember {
  final String id;
  final String clubId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  const ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}
