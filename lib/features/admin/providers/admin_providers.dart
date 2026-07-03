import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/admin_repository.dart';
import '../../../models/user_profile.dart';
import '../../../models/system_activity.dart';
import '../../../models/content_report.dart';
import '../../clubs/providers/clubs_provider.dart';

// Provides the Supabase Client (assuming it's a singleton here or could be retrieved from a core provider)
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

// Provides the AdminRepository instance
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

// Dashboard Stats Data Class
class DashboardStats {
  final int totalStudents;
  final int activeClubs;
  final int totalEvents;

  DashboardStats({
    required this.totalStudents,
    required this.activeClubs,
    required this.totalEvents,
  });
}

// Provider for Dashboard Stats
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  
  final stats = await repo.getPlatformStatistics();
  
  return DashboardStats(
    totalStudents: stats['total_students'] as int,
    activeClubs: stats['active_clubs'] as int,
    totalEvents: stats['total_events'] as int,
  );
});

// Member Management Stats Data Class
class MemberStats {
  final int totalMembers;
  final int activeNow; // Mocked or calculated differently in future
  final int executives;
  final int pendingSync; // Mocked

  MemberStats({
    required this.totalMembers,
    required this.activeNow,
    required this.executives,
    required this.pendingSync,
  });
}

// Provider for Member Stats
final memberStatsProvider = FutureProvider<MemberStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  
  final stats = await repo.getPlatformStatistics();
  
  return MemberStats(
    totalMembers: stats['total_students'] as int,
    activeNow: stats['active_members'] as int, // Using active members for 'Active Now'
    executives: stats['total_executives'] as int,
    pendingSync: 0,
  );
});

// Stream Provider for System Activities
final systemActivityStreamProvider = StreamProvider<List<SystemActivity>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getSystemActivitiesStream();
});

// Search Query Provider for Member Management
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

// Paginated User Profiles Provider
final paginatedUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final searchQuery = ref.watch(memberSearchQueryProvider);
  
  // Just fetching first 20 for simplicity in this implementation
  return await repo.getUsers(searchQuery: searchQuery, limit: 20, offset: 0);
});

// StateNotifier for Admin Actions (Promote/Revoke) to handle loading states
class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> promoteToExecutive(String userId, String clubId, String roleTitle) async {
    state = const AsyncValue.loading();
    try {
      await _repository.promoteToExecutive(userId, clubId, roleTitle);
      // Invalidate the users list so it refreshes
      _ref.invalidate(paginatedUsersProvider);
      _ref.invalidate(memberStatsProvider);
      _ref.invalidate(clubExecutivesProvider(clubId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revokeExecutive(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.revokeExecutive(userId);
      // Invalidate the users list so it refreshes
      _ref.invalidate(paginatedUsersProvider);
      _ref.invalidate(memberStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// StateNotifier for Creating Clubs
class CreateClubNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  
  CreateClubNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createClub({
    required String name,
    required String focusArea,
    required String description,
    required String iconName,
    required String colorHex,
    dynamic logoFile,
    dynamic coverFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createClub(
        name: name,
        focusArea: focusArea,
        description: description,
        iconName: iconName,
        colorHex: colorHex,
        logoFile: logoFile,
        coverFile: coverFile,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createClubNotifierProvider = StateNotifierProvider<CreateClubNotifier, AsyncValue<void>>((ref) {
  return CreateClubNotifier(ref.watch(adminRepositoryProvider));
});

final adminActionProvider = StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>((ref) {
  return AdminActionNotifier(ref.watch(adminRepositoryProvider), ref);
});

// Content Moderation Providers

// Provider for top stats bar
final moderationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getModerationStats();
});

// State for active filter tab (e.g. 'Posts', 'Events', 'Comments', 'All')
final moderationFilterProvider = StateProvider<String>((ref) => 'All');

// Provider for the moderation queue list
final contentReportsProvider = FutureProvider<List<ContentReport>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(moderationFilterProvider);
  return await repo.getContentReports(filterType: filter);
});

// StateNotifier for Mod Actions (Approve/Delete)
class ModerationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  ModerationActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> handleReport(String reportId, String action, String contentType, String? entityId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resolveReport(reportId, action, contentType, entityId);
      // Invalidate the queue list and stats
      _ref.invalidate(contentReportsProvider);
      _ref.invalidate(moderationStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final moderationActionProvider = StateNotifierProvider<ModerationActionNotifier, AsyncValue<void>>((ref) {
  return ModerationActionNotifier(ref.watch(adminRepositoryProvider), ref);
});

