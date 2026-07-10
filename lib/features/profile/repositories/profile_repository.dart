import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/services/supabase_query_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/user_profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Fetches current user profile cleanly with explicit column narrowing
  Future<UserProfile?> getUserProfile(String userId) async {
    return SupabaseQueryHelper.runQuery('getUserProfile', () async {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    }, fallback: null);
  }

  /// Updates profile data securely
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    return SupabaseQueryHelper.runQuery('updateProfile', () async {
      final cleanUpdates = Map<String, dynamic>.from(updates);
      cleanUpdates['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('profiles')
          .update(cleanUpdates)
          .eq('id', userId);
      AppLogger.info('Updated profile for user $userId');
    });
  }

  /// Uploads avatar binary and updates profile avatar_url
  Future<String> uploadAvatar(String userId, dynamic file) async {
    return SupabaseQueryHelper.runQuery('uploadAvatar', () async {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'avatars/$fileName';

      if (file is Uint8List) {
        await _client.storage.from('avatars').uploadBinary(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        await _client.storage.from('avatars').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      final publicUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      await _client.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);
      AppLogger.info('Uploaded avatar for user $userId');
      return publicUrl;
    });
  }
}
