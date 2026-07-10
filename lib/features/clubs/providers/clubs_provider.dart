import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/club.dart';
import '../../../models/club_executive.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/clubs_repository.dart';

final clubsRepositoryProvider = Provider<ClubsRepository>((ref) {
  return ClubsRepository();
});

final clubsProvider = FutureProvider<List<Club>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final repository = ref.read(clubsRepositoryProvider);
  return repository.getClubs();
});

final clubDetailProvider = FutureProvider.family<Club?, String>((ref, clubSlugOrId) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return null;

  final repository = ref.read(clubsRepositoryProvider);
  return repository.getClubByIdOrSlug(clubSlugOrId);
});

final clubExecutivesProvider = StreamProvider.family<List<ClubExecutive>, String>((ref, clubId) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return Stream.value([]);

  final channel = SupabaseConfig.client
      .channel('public:rt_club_execs_${clubId}_${DateTime.now().millisecondsSinceEpoch}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'club_executives',
        callback: (payload) {
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  return Stream.fromFuture(ref.read(clubsRepositoryProvider).getClubExecutives(clubId));
});

// User's followed clubs stream
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
  final Ref _ref;
  final ClubsRepository _repository;

  FollowClubNotifier(this._ref, this._repository) : super(const AsyncValue.data(null));

  Future<void> toggleMembership(String clubId, bool isCurrentlyFollowing) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleMembership(clubId, isCurrentlyFollowing);
      _ref.invalidate(clubDetailProvider(clubId));
      _ref.invalidate(clubsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> follow(String clubId) async {
    await toggleMembership(clubId, false);
  }

  Future<void> unfollow(String clubId) async {
    await toggleMembership(clubId, true);
  }
}

final followClubNotifierProvider =
    StateNotifierProvider<FollowClubNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(clubsRepositoryProvider);
      return FollowClubNotifier(ref, repo);
    });

final toggleClubMembershipProvider = followClubNotifierProvider;

class EditClubNotifier extends StateNotifier<AsyncValue<void>> {
  final ClubsRepository _repository;

  EditClubNotifier(this._repository) : super(const AsyncValue.data(null));

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
      await _repository.updateClubProfile(
        clubId,
        name: name,
        bio: bio,
        categories: categories,
        meetingSchedule: meetingSchedule,
        location: location,
        logoUrl: logoUrl,
        coverImageUrl: coverImageUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final editClubNotifierProvider =
    StateNotifierProvider<EditClubNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(clubsRepositoryProvider);
      return EditClubNotifier(repo);
    });
