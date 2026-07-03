class SystemActivity {
  final String id;
  final String? actorId;
  final String actorName;
  final String actorRole;
  final String actionType;
  final String entityType;
  final String? entityId;
  final String description;
  final DateTime createdAt;

  SystemActivity({
    required this.id,
    this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.description,
    required this.createdAt,
  });

  factory SystemActivity.fromJson(Map<String, dynamic> json) {
    return SystemActivity(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String,
      actorRole: json['actor_role'] as String,
      actionType: json['action_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_role': actorRole,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
