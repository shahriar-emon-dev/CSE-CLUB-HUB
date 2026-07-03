class ContentReport {
  final String reportId;
  final String contentType;
  final String status;
  final String severity;
  final String reason;
  final DateTime createdAt;
  final String? entityId;
  final String? contentTitle;
  final String? contentText;
  final String? authorId;
  final String? authorName;
  final String? authorAvatar;
  final String? reporterName;

  ContentReport({
    required this.reportId,
    required this.contentType,
    required this.status,
    required this.severity,
    required this.reason,
    required this.createdAt,
    this.entityId,
    this.contentTitle,
    this.contentText,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    this.reporterName,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      reportId: json['report_id'] as String,
      contentType: json['content_type'] as String,
      status: json['status'] as String,
      severity: json['severity'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      entityId: json['entity_id'] as String?,
      contentTitle: json['content_title'] as String?,
      contentText: json['content_text'] as String?,
      authorId: json['author_id'] as String?,
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      reporterName: json['reporter_name'] as String?,
    );
  }
}
