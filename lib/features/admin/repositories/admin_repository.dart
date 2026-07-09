import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_profile.dart';
import '../../../models/system_activity.dart';
import '../../../models/content_report.dart';
import 'dart:typed_data';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/supabase_query_helper.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  void _checkSuperAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Unauthorized: No active session token.');
    }
  }

  /// Fetches platform statistics dynamically using the single-pass database RPC
  /// (`get_admin_dashboard_metrics`). Falls back safely if the RPC is unavailable during migration.
  Future<Map<String, dynamic>> getPlatformStatistics() async {
    return SupabaseQueryHelper.runQuery('getPlatformStatistics', () async {
      try {
        final rpcResult = await _supabase.rpc('get_admin_dashboard_metrics');
        if (rpcResult != null && rpcResult is Map) {
          final map = Map<String, dynamic>.from(rpcResult);
          map['recent_registrations'] = map['recent_registrations'] ?? 0;
          map['recent_avatars'] = <String>[];
          map['avg_response_minutes'] = map['avg_response_minutes'] ?? 0;
          map['club_member_counts'] = <String, int>{};
          return map;
        }
      } catch (e, st) {
        AppLogger.error('RPC get_admin_dashboard_metrics unavailable or failed, falling back to parallel query stats', e, st);
      }

      // Safe Parallel Fallback Query
      final results = await Future.wait([
        _supabase.from('profiles').select('id, role, status, avatar_url, created_at'),
        _supabase.from('clubs').select('id, status'),
        _supabase.from('events').select('id, is_cancelled'),
        _supabase.from('content_reports').select('id, status, severity, resolved_at'),
        _supabase.from('club_posts').select('id'),
        _supabase.from('comments').select('id'),
        _supabase.from('club_post_reactions').select('reaction_type'),
        _supabase.from('event_rsvps').select('id'),
      ]);

      final profiles = results[0] as List;
      final clubs = results[1] as List;
      final events = results[2] as List;
      final reports = results[3] as List;
      final posts = results[4] as List;
      final comments = results[5] as List;
      final reactions = results[6] as List;
      final rsvps = results[7] as List;

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

      final now = DateTime.now();
      int recentRegistrations = 0;
      final recentAvatars = <String>[];
      for (final p in profiles) {
        final createdAtStr = p['created_at']?.toString();
        if (createdAtStr != null) {
          final dt = DateTime.tryParse(createdAtStr)?.toLocal();
          if (dt != null && now.difference(dt).inDays <= 30) {
            recentRegistrations++;
          }
        }
        final avatar = p['avatar_url']?.toString() ?? '';
        if (avatar.isNotEmpty && recentAvatars.length < 5) {
          recentAvatars.add(avatar);
        }
      }

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
        'total_events': events.length,
        'total_posts': posts.length,
        'total_comments': comments.length,
        'total_reactions': reactions.length,
        'total_rsvps': rsvps.length,
        'recent_registrations': recentRegistrations,
        'recent_avatars': recentAvatars,
        'pending_reports': pendingReports,
        'high_risk_reports': highRiskReports,
        'resolved_today_reports': resolvedToday,
        'avg_response_minutes': 0,
        'club_member_counts': <String, int>{},
      };
    }, fallback: {
      'total_students': 0,
      'active_members': 0,
      'total_executives': 0,
      'active_clubs': 0,
      'total_events': 0,
      'total_posts': 0,
      'total_comments': 0,
      'total_reactions': 0,
      'total_rsvps': 0,
      'recent_registrations': 0,
      'recent_avatars': <String>[],
      'pending_reports': 0,
      'high_risk_reports': 0,
      'resolved_today_reports': 0,
      'avg_response_minutes': 0,
      'club_member_counts': <String, int>{},
    });
  }

  /// System Activity Stream
  Stream<List<SystemActivity>> getSystemActivitiesStream() {
    try {
      return _supabase.from('system_activities').stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data.map((e) => SystemActivity.fromJson(e)).toList())
        .handleError((error) {
          AppLogger.error('Error in system_activities stream: $error');
          return <SystemActivity>[];
        });
    } catch (e, st) {
      AppLogger.error('Failed to create system_activities stream', e, st);
      return Stream.value([]);
    }
  }

  /// Member Management Queries (Paginated & Column-Optimized)
  Future<List<UserProfile>> getUsers({String? searchQuery, int limit = 15, int offset = 0}) async {
    return SupabaseQueryHelper.runQuery('getUsers', () async {
      var query = _supabase.from('profiles').select('id, email, full_name, role, status, avatar_url, student_id, department, batch, skills, bio, created_at');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('full_name.ilike.%$searchQuery%,student_id.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }
      
      final response = await query.order('created_at', ascending: false).range(offset, SupabaseQueryHelper.calcEndRange(offset, limit));
      return (response as List).map((e) => UserProfile.fromJson(e)).toList();
    }, fallback: <UserProfile>[]);
  }

  /// Role Management
  Future<void> promoteToExecutive(String userId, String clubId, String roleTitle) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('promoteToExecutive', () async {
      await _supabase.rpc('assign_executive_role', params: {
        'p_user_id': userId,
        'p_club_id': clubId,
        'p_role_title': roleTitle,
      });
      AppLogger.info('Promoted user $userId to $roleTitle in club $clubId');
    });
  }

  Future<void> revokeExecutive(String userId) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('revokeExecutive', () async {
      await _supabase.rpc('revoke_executive_role', params: {
        'p_user_id': userId,
      });
      AppLogger.info('Revoked executive status for user $userId');
    });
  }

  /// Club Management
  Future<void> createClub({
    required String name,
    required String focusArea,
    required String description,
    required String iconName,
    required String colorHex,
    dynamic logoFile,
    dynamic coverFile,
  }) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('createClub', () async {
      String? logoUrl;
      String? coverUrl;

      Future<String?> uploadClubImage(dynamic file, String type) async {
        if (file == null) return null;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$type.jpg';
        final storagePath = 'clubs/$fileName';
        
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
      AppLogger.info('Created new club: $name');
    });
  }

  /// Content Moderation (Paginated & Filtered)
  Future<List<ContentReport>> getContentReports({String? filterType, int limit = 20, int offset = 0}) async {
    return SupabaseQueryHelper.runQuery('getContentReports', () async {
      var query = _supabase.from('admin_content_reports_view').select().eq('status', 'pending');
      
      if (filterType != null && filterType != 'All') {
        final type = filterType.toLowerCase();
        if (type.startsWith('post')) {
          query = query.eq('content_type', 'post');
        } else if (type.startsWith('event')) {
          query = query.eq('content_type', 'event');
        } else if (type.startsWith('comment')) {
          query = query.eq('content_type', 'comment');
        }
      }
      
      final response = await query.order('created_at', ascending: false).range(offset, SupabaseQueryHelper.calcEndRange(offset, limit));
      return (response as List).map((e) => ContentReport.fromJson(e)).toList();
    }, fallback: <ContentReport>[]);
  }

  Future<Map<String, int>> getModerationStats() async {
    final stats = await getPlatformStatistics();
    return {
      'inQueue': (stats['pending_reports'] ?? 0) as int,
      'highRisk': (stats['high_risk_reports'] ?? 0) as int,
      'resolvedToday': (stats['resolved_today_reports'] ?? 0) as int,
      'avgResponseMinutes': (stats['avg_response_minutes'] ?? 0) as int,
    };
  }

  Future<void> resolveReport(String reportId, String action, String contentType, String? entityId) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('resolveReport', () async {
      await _supabase.from('content_reports').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_by': _supabase.auth.currentUser?.id,
      }).eq('id', reportId);

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
      
      await _supabase.from('moderation_logs').insert({
        'moderator_id': _supabase.auth.currentUser!.id,
        'report_id': reportId,
        'action': action == 'delete' ? 'deleted' : 'approved',
        'notes': 'Action performed via Admin Portal',
      });
      AppLogger.info('Resolved report $reportId with action $action');
    });
  }

  /// System Settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('getSystemSettings', () async {
      final response = await _supabase.from('system_settings').select('setting_key, setting_value');
      return {for (var item in response) item['setting_key'] as String: item['setting_value']};
    }, fallback: <String, dynamic>{});
  }

  Future<void> updateSystemSetting(String key, Map<String, dynamic> value) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('updateSystemSetting', () async {
      await _supabase.from('system_settings').upsert({
        'setting_key': key,
        'setting_value': value,
        'updated_by': _supabase.auth.currentUser?.id,
      }, onConflict: 'setting_key');
      AppLogger.info('Updated system setting $key');
    });
  }

  /// User Management Actions
  Future<void> updateUserStatus(String userId, String newStatus) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('updateUserStatus', () async {
      await _supabase.from('profiles').update({'status': newStatus}).eq('id', userId);
      await _supabase.from('moderation_logs').insert({
        'moderator_id': _supabase.auth.currentUser!.id,
        'action': 'user_status_changed',
        'notes': 'User $userId status set to $newStatus',
      });
      AppLogger.info('Updated user $userId status to $newStatus');
    });
  }

  Future<void> deleteUserAccount(String userId) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('deleteUserAccount', () async {
      await _supabase.from('profiles').delete().eq('id', userId);
      await _supabase.from('moderation_logs').insert({
        'moderator_id': _supabase.auth.currentUser!.id,
        'action': 'user_deleted',
        'notes': 'Account deleted for user $userId via Admin Portal',
      });
      AppLogger.info('Deleted profile account for user $userId');
    });
  }

  Future<void> updateClubDetails({
    required String clubId,
    required String name,
    required String focusArea,
    required String description,
    required String colorHex,
    String? logoUrl,
    String? coverUrl,
  }) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('updateClubDetails', () async {
      final updateData = {
        'name': name,
        'focus_area': focusArea,
        'description': description,
        'color_hex': colorHex,
      };
      if (logoUrl != null) updateData['logo_url'] = logoUrl;
      if (coverUrl != null) updateData['cover_image_url'] = coverUrl;

      await _supabase.from('clubs').update(updateData).eq('id', clubId);
      AppLogger.info('Updated details for club $clubId');
    });
  }

  Future<void> cancelOrDeleteEvent(String eventId, {required bool isDelete}) async {
    _checkSuperAdmin();
    return SupabaseQueryHelper.runQuery('cancelOrDeleteEvent', () async {
      if (isDelete) {
        await _supabase.from('events').delete().eq('id', eventId);
      } else {
        await _supabase.from('events').update({'is_cancelled': true}).eq('id', eventId);
      }
      AppLogger.info('Event $eventId processed with delete=$isDelete');
    });
  }
}
