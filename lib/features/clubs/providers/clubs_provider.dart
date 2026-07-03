import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club.dart';
import '../../../models/club_executive.dart';
final clubsProvider = FutureProvider<List<Club>>((ref) async {
  final data = await SupabaseConfig.client
      .from('club_list_view')
      .select()
      .order('name', ascending: true);
  return data.map((e) => Club.fromJson(e)).toList();
});

final clubDetailProvider = FutureProvider.family<Club?, String>((ref, clubSlug) async {
  final data = await SupabaseConfig.client
      .from('club_list_view')
      .select()
      .eq('slug', clubSlug);
  return data.isNotEmpty ? Club.fromJson(data.first) : null;
});

final clubExecutivesProvider = FutureProvider.family<List<ClubExecutive>, String>((ref, clubId) async {
  final response = await SupabaseConfig.client
      .from('club_executives_view')
      .select()
      .eq('club_id', clubId);

  return (response as List).map((e) => ClubExecutive.fromJson(e)).toList();
});

// User's followed clubs
final followedClubsProvider = StreamProvider<List<String>>((ref) {
  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return Stream.value([]);
  
  return SupabaseConfig.client
      .from('club_followers')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((e) => e['club_id'] as String).toList());
});

class FollowClubNotifier extends StateNotifier<AsyncValue<void>> {
  FollowClubNotifier() : super(const AsyncValue.data(null));

  Future<void> follow(String clubId) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");
      
      await SupabaseConfig.client.from('club_followers').insert({
        'club_id': clubId,
        'user_id': userId,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> unfollow(String clubId) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");
      
      await SupabaseConfig.client
          .from('club_followers')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final followClubNotifierProvider =
    StateNotifierProvider<FollowClubNotifier, AsyncValue<void>>((_) => FollowClubNotifier());

class EditClubNotifier extends StateNotifier<AsyncValue<void>> {
  EditClubNotifier() : super(const AsyncValue.data(null));

  Future<void> updateClubProfile(String clubId, {
    String? name,
    String? bio,
    List<String>? categories,
    String? meetingSchedule,
    String? location,
    String? logoUrl,
    String? coverImageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception("Not logged in");

      // Note: RLS ensures only executives/admins can update
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (bio != null) updates['description'] = bio;
      if (categories != null) updates['categories'] = categories;
      if (meetingSchedule != null) updates['meeting_schedule'] = meetingSchedule;
      if (location != null) updates['location'] = location;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;

      await SupabaseConfig.client
          .from('clubs')
          .update(updates)
          .eq('id', clubId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final editClubNotifierProvider =
    StateNotifierProvider<EditClubNotifier, AsyncValue<void>>((_) => EditClubNotifier());
