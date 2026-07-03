import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_profile.dart';
import '../../../models/system_activity.dart';
import '../../../models/content_report.dart';
import 'dart:typed_data';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // Fetches all stats from the platform_statistics view
  Future<Map<String, dynamic>> getPlatformStatistics() async {
    final response = await _supabase.from('platform_statistics').select().single();
    return response;
  }

  // System Activity Stream
  Stream<List<SystemActivity>> getSystemActivitiesStream() {
    return _supabase.from('system_activities').stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(50)
      .map((data) => data.map((e) => SystemActivity.fromJson(e)).toList());
  }

  // Member Management Queries
  Future<List<UserProfile>> getUsers({String? searchQuery, int limit = 10, int offset = 0}) async {
    var query = _supabase.from('profiles').select();
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('full_name.ilike.%$searchQuery%,student_id.ilike.%$searchQuery%');
    }
    
    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return (response as List).map((e) => UserProfile.fromJson(e)).toList();
  }

  // Role Management
  Future<void> promoteToExecutive(String userId, String clubId, String roleTitle) async {
    await _supabase.rpc('assign_executive_role', params: {
      'p_user_id': userId,
      'p_club_id': clubId,
      'p_role_title': roleTitle,
    });
  }

  Future<void> revokeExecutive(String userId) async {
    await _supabase.rpc('revoke_executive_role', params: {
      'p_user_id': userId,
    });
  }

  // Club Management
  Future<void> createClub({
    required String name,
    required String focusArea,
    required String description,
    required String iconName,
    required String colorHex,
    dynamic logoFile, // Can be File or bytes depending on platform
    dynamic coverFile,
  }) async {
    String? logoUrl;
    String? coverUrl;

    // Helper to upload image if provided
    Future<String?> uploadClubImage(dynamic file, String type) async {
      if (file == null) return null;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$type.jpg';
      final storagePath = 'clubs/$fileName';
      
      // Upload using proper method based on file type (web vs mobile)
      if (file is Uint8List) {
        await _supabase.storage.from('club-logos').uploadBinary(storagePath, file, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      } else {
        await _supabase.storage.from('club-logos').upload(storagePath, file);
      }
      return _supabase.storage.from('club-logos').getPublicUrl(storagePath);
    }

    logoUrl = await uploadClubImage(logoFile, 'logo');
    coverUrl = await uploadClubImage(coverFile, 'cover');

    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    await _supabase.from('clubs').insert({
      'name': name,
      'focus_area': focusArea,
      'description': description,
      'slug': slug,
      'icon_name': iconName,
      'color_hex': colorHex,
      'logo_url': logoUrl,
      'cover_image_url': coverUrl,
    });
  }

  // Content Moderation
  Future<List<ContentReport>> getContentReports({String? filterType}) async {
    var query = _supabase.from('admin_content_reports_view').select().eq('status', 'pending');
    
    if (filterType != null && filterType != 'All') {
      // Map 'Posts', 'Events', 'Comments' to 'post', 'event', 'comment'
      final type = filterType.toLowerCase();
      if (type.startsWith('post')) {
        query = query.eq('content_type', 'post');
      } else if (type.startsWith('event')) {
        query = query.eq('content_type', 'event');
      } else if (type.startsWith('comment')) {
        query = query.eq('content_type', 'comment');
      }
    }
    
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => ContentReport.fromJson(e)).toList();
  }

  Future<Map<String, int>> getModerationStats() async {
    final stats = await getPlatformStatistics();
    return {
      'inQueue': stats['pending_reports'] as int,
      'highRisk': stats['high_risk_reports'] as int,
      'resolvedToday': stats['resolved_today_reports'] as int,
    };
  }

  Future<void> resolveReport(String reportId, String action, String contentType, String? entityId) async {
    // action is either 'approve' or 'delete'
    // 1. Mark report as resolved
    await _supabase.from('content_reports').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': _supabase.auth.currentUser?.id,
    }).eq('id', reportId);

    // 2. Perform the physical/soft deletion if requested
    if (action == 'delete' && entityId != null) {
      if (contentType == 'post') {
        await _supabase.from('forum_posts').update({'is_deleted': true}).eq('id', entityId);
      } else if (contentType == 'event') {
        await _supabase.from('events').update({'is_cancelled': true}).eq('id', entityId);
      } else if (contentType == 'comment') {
        await _supabase.from('comments').update({'is_deleted': true}).eq('id', entityId);
      } else if (contentType == 'blog') {
        await _supabase.from('blogs').update({'status': 'rejected'}).eq('id', entityId);
      }
    }
    
    // 3. Log the moderation action
    if (_supabase.auth.currentUser != null) {
      await _supabase.from('moderation_logs').insert({
        'moderator_id': _supabase.auth.currentUser!.id,
        'report_id': reportId,
        'action': action == 'delete' ? 'deleted' : 'approved',
        'notes': 'Action performed via Admin Portal',
      });
    }
  }
}
