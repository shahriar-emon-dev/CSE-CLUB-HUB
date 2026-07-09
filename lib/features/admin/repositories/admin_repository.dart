import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_profile.dart';
import '../../../models/system_activity.dart';
import '../../../models/content_report.dart';
import 'dart:typed_data';
import '../../../core/utils/app_logger.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  void _checkSuperAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Unauthorized: No active session token.');
    }
    // Checking super_admin role might require checking the profile, but for now we enforce 
    // that the token is present. RLS handles the rest securely.
  }

  // Fetches live platform statistics directly from active database tables
  Future<Map<String, dynamic>> getPlatformStatistics() async {
    try {
      final results = await Future.wait([
        _supabase.from('profiles').select('id, role, status'),
        _supabase.from('clubs').select('id, status'),
        _supabase.from('events').select('id'),
        _supabase.from('content_reports').select('id, status, severity, resolved_at'),
      ]);

      final profiles = results[0] as List;
      final clubs = results[1] as List;
      final events = results[2] as List;
      final reports = results[3] as List;

      final totalStudents = profiles.length;
      final activeMembers = profiles.where((p) {
        final st = (p['status'] ?? '').toString().toLowerCase();
        return st == 'active' || st.isEmpty;
      }).length;

      final totalExecutives = profiles.where((p) {
        final role = (p['role'] ?? '').toString().toLowerCase();
        return role.contains('executive') || role.contains('admin');
      }).length;

      final activeClubs = clubs.where((c) {
        final st = (c['status'] ?? '').toString().toLowerCase();
        return st == 'active' || st.isEmpty;
      }).length;

      final totalEvents = events.length;

      final now = DateTime.now();
      int pendingReports = 0;
      int highRiskReports = 0;
      int resolvedToday = 0;

      for (final r in reports) {
        final st = (r['status'] ?? '').toString().toLowerCase();
        final pr = (r['severity'] ?? '').toString().toLowerCase();
        final resAtStr = r['resolved_at']?.toString();

        if (st == 'pending') {
          pendingReports++;
          if (pr == 'high' || pr == 'urgent') {
            highRiskReports++;
          }
        } else if (st == 'resolved' && resAtStr != null) {
          final dt = DateTime.tryParse(resAtStr)?.toLocal();
          if (dt != null && dt.year == now.year && dt.month == now.month && dt.day == now.day) {
            resolvedToday++;
          }
        }
      }

      return {
        'total_students': totalStudents,
        'active_members': activeMembers,
        'total_executives': totalExecutives,
        'active_clubs': activeClubs,
        'total_events': totalEvents,
        'pending_reports': pendingReports,
        'high_risk_reports': highRiskReports,
        'resolved_today_reports': resolvedToday,
      };
    } catch (e, st) {
      AppLogger.error('Failed to fetch parallel platform statistics, attempting fallback queries', e, st);
      int totalStudents = 0;
      int activeMembers = 0;
      int totalExecutives = 0;
      int activeClubs = 0;
      int totalEvents = 0;
      int pendingReports = 0;
      int highRiskReports = 0;
      int resolvedToday = 0;

      try {
        final p = await _supabase.from('profiles').select('id, role, status');
        final list = p as List;
        totalStudents = list.length;
        activeMembers = list.where((item) => (item['status'] ?? 'active').toString().toLowerCase() == 'active').length;
        totalExecutives = list.where((item) {
          final r = (item['role'] ?? '').toString().toLowerCase();
          return r.contains('executive') || r.contains('admin');
        }).length;
      } catch (_) {}

      try {
        final c = await _supabase.from('clubs').select('id');
        activeClubs = (c as List).length;
      } catch (_) {}

      try {
        final ev = await _supabase.from('events').select('id');
        totalEvents = (ev as List).length;
      } catch (_) {}

      try {
        final rep = await _supabase.from('content_reports').select('id, status, severity');
        for (final item in rep as List) {
          if ((item['status'] ?? '').toString().toLowerCase() == 'pending') {
            pendingReports++;
            final pr = (item['severity'] ?? '').toString().toLowerCase();
            if (pr == 'high' || pr == 'urgent') highRiskReports++;
          }
        }
      } catch (_) {}

      return {
        'total_students': totalStudents,
        'active_members': activeMembers,
        'total_executives': totalExecutives,
        'active_clubs': activeClubs,
        'total_events': totalEvents,
        'pending_reports': pendingReports,
        'high_risk_reports': highRiskReports,
        'resolved_today_reports': resolvedToday,
      };
    }
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
    _checkSuperAdmin();
    try {
      await _supabase.rpc('assign_executive_role', params: {
        'p_user_id': userId,
        'p_club_id': clubId,
        'p_role_title': roleTitle,
      });
      AppLogger.info('Promoted user $userId to $roleTitle in club $clubId');
    } catch (e, st) {
      AppLogger.error('Failed to promote user $userId', e, st);
      rethrow;
    }
  }

  Future<void> revokeExecutive(String userId) async {
    _checkSuperAdmin();
    try {
      await _supabase.rpc('revoke_executive_role', params: {
        'p_user_id': userId,
      });
      AppLogger.info('Revoked executive status for user $userId');
    } catch (e, st) {
      AppLogger.error('Failed to revoke executive status for user $userId', e, st);
      rethrow;
    }
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

    _checkSuperAdmin();
    try {
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
      AppLogger.info('Created new club: $name');
    } catch (e, st) {
      AppLogger.error('Failed to create club $name', e, st);
      rethrow;
    }
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
      'inQueue': (stats['pending_reports'] ?? 0) as int,
      'highRisk': (stats['high_risk_reports'] ?? 0) as int,
      'resolvedToday': (stats['resolved_today_reports'] ?? 0) as int,
    };
  }

  Future<void> resolveReport(String reportId, String action, String contentType, String? entityId) async {
    _checkSuperAdmin();
    try {
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
          await _supabase.from('club_posts').delete().eq('id', entityId);
        } else if (contentType == 'event') {
          await _supabase.from('events').update({'is_cancelled': true}).eq('id', entityId);
        } else if (contentType == 'comment') {
          await _supabase.from('comments').update({'is_deleted': true}).eq('id', entityId);
        } else if (contentType == 'blog') {
          await _supabase.from('blogs').update({'status': 'rejected'}).eq('id', entityId);
        }
      }
      
      // 3. Log the moderation action
      await _supabase.from('moderation_logs').insert({
        'moderator_id': _supabase.auth.currentUser!.id,
        'report_id': reportId,
        'action': action == 'delete' ? 'deleted' : 'approved',
        'notes': 'Action performed via Admin Portal',
      });
      AppLogger.info('Resolved report $reportId with action $action');
    } catch (e, st) {
      AppLogger.error('Failed to resolve report $reportId', e, st);
      rethrow;
    }
  }

  // System Settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    _checkSuperAdmin();
    final response = await _supabase.from('system_settings').select();
    return {for (var item in response) item['setting_key'] as String: item['setting_value']};
  }

  Future<void> updateSystemSetting(String key, Map<String, dynamic> value) async {
    _checkSuperAdmin();
    try {
      await _supabase.from('system_settings').upsert({
        'setting_key': key,
        'setting_value': value,
        'updated_by': _supabase.auth.currentUser?.id,
      }, onConflict: 'setting_key');
      AppLogger.info('Updated system setting $key');
    } catch (e, st) {
      AppLogger.error('Failed to update system setting $key', e, st);
      rethrow;
    }
  }
}
