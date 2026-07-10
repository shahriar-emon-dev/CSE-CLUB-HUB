import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/admin_repository.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/user_profile.dart';
import '../../../models/system_activity.dart';
import '../../../models/content_report.dart';
import '../../../models/club.dart';
import '../../../models/club_executive.dart';
import '../../../models/event.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../auth/providers/auth_provider.dart';

// Provides the Supabase Client (assuming it's a singleton here or could be retrieved from a core provider)
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

// Provides the AdminRepository instance
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

// Dashboard Stats Data Class
class DashboardStats {
  final int totalStudents;
  final int activeMembers;
  final int totalExecutives;
  final int activeClubs;
  final int totalEvents;
  final int pendingReports;
  final int highRiskReports;
  final int resolvedTodayReports;
  final int totalPosts;
  final int totalComments;
  final int totalReactions;
  final int totalRsvps;
  final int recentRegistrations;
  final List<String> recentAvatars;
  final Map<String, int> clubMemberCounts;

  DashboardStats({
    required this.totalStudents,
    this.activeMembers = 0,
    this.totalExecutives = 0,
    required this.activeClubs,
    required this.totalEvents,
    required this.pendingReports,
    this.highRiskReports = 0,
    this.resolvedTodayReports = 0,
    this.totalPosts = 0,
    this.totalComments = 0,
    this.totalReactions = 0,
    this.totalRsvps = 0,
    this.recentRegistrations = 0,
    this.recentAvatars = const [],
    this.clubMemberCounts = const {},
  });
}

// Provider for Dashboard Stats
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return DashboardStats(totalStudents: 0, activeClubs: 0, totalEvents: 0, pendingReports: 0);

  final channelName = 'public:dashboard_stats';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clubs',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'content_reports',
          callback: (payload) => ref.invalidateSelf())
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repo = ref.watch(adminRepositoryProvider);
  final stats = await repo.getPlatformStatistics();
  
  return DashboardStats(
    totalStudents: (stats['total_students'] ?? 0) as int,
    activeMembers: (stats['active_members'] ?? 0) as int,
    totalExecutives: (stats['total_executives'] ?? 0) as int,
    activeClubs: (stats['active_clubs'] ?? 0) as int,
    totalEvents: (stats['total_events'] ?? 0) as int,
    pendingReports: (stats['pending_reports'] ?? 0) as int,
    highRiskReports: (stats['high_risk_reports'] ?? 0) as int,
    resolvedTodayReports: (stats['resolved_today_reports'] ?? 0) as int,
    totalPosts: (stats['total_posts'] ?? 0) as int,
    totalComments: (stats['total_comments'] ?? 0) as int,
    totalReactions: (stats['total_reactions'] ?? 0) as int,
    totalRsvps: (stats['total_rsvps'] ?? 0) as int,
    recentRegistrations: (stats['recent_registrations'] ?? 0) as int,
    recentAvatars: (stats['recent_avatars'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    clubMemberCounts: (stats['club_member_counts'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
  );
});

// Member Management Stats Data Class
class MemberStats {
  final int totalMembers;
  final int activeNow; // Mocked or calculated differently in future
  final int executives;
  final int pendingSync; // Mocked
  final int recentGrowth;

  MemberStats({
    required this.totalMembers,
    required this.activeNow,
    required this.executives,
    required this.pendingSync,
    this.recentGrowth = 0,
  });
}

// Provider for Member Stats
final memberStatsProvider = FutureProvider<MemberStats>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return MemberStats(totalMembers: 0, activeNow: 0, executives: 0, pendingSync: 0);

  final channelName = 'public:member_stats';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) => ref.invalidateSelf())
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clubs',
          callback: (payload) => ref.invalidateSelf())
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repo = ref.watch(adminRepositoryProvider);
  final stats = await repo.getPlatformStatistics();
  
  return MemberStats(
    totalMembers: (stats['total_students'] ?? 0) as int,
    activeNow: (stats['active_members'] ?? 0) as int, // Using active members for 'Active Now'
    executives: (stats['total_executives'] ?? 0) as int,
    pendingSync: (stats['pending_reports'] ?? 0) as int,
    recentGrowth: (stats['recent_registrations'] ?? 0) as int,
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
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

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
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(memberStatsProvider);
      _ref.invalidate(moderationStatsProvider);
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
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(memberStatsProvider);
      _ref.invalidate(moderationStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// StateNotifier for Creating Clubs
class CreateClubNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;
  
  CreateClubNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(memberStatsProvider);
      _ref.invalidate(clubsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createClubNotifierProvider = StateNotifierProvider<CreateClubNotifier, AsyncValue<void>>((ref) {
  return CreateClubNotifier(ref.watch(adminRepositoryProvider), ref);
});

final adminActionProvider = StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>((ref) {
  return AdminActionNotifier(ref.watch(adminRepositoryProvider), ref);
});

// Content Moderation Providers

// Provider for top stats bar
final moderationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return {};

  final channelName = 'public:mod_stats';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'content_reports',
          callback: (payload) => ref.invalidateSelf())
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getModerationStats();
});

// State for active filter tab (e.g. 'Posts', 'Events', 'Comments', 'All')
final moderationFilterProvider = StateProvider<String>((ref) => 'All');

// Provider for the moderation queue list
final contentReportsProvider = FutureProvider<List<ContentReport>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:content_reports';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'content_reports',
          callback: (payload) => ref.invalidateSelf())
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

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
      _ref.invalidate(dashboardStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final moderationActionProvider = StateNotifierProvider<ModerationActionNotifier, AsyncValue<void>>((ref) {
  return ModerationActionNotifier(ref.watch(adminRepositoryProvider), ref);
});

// System Settings Provider
final systemSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return {};

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getSystemSettings();
});

class SystemSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  SystemSettingsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateSetting(String key, Map<String, dynamic> value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSystemSetting(key, value);
      _ref.invalidate(systemSettingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final systemSettingsActionProvider = StateNotifierProvider<SystemSettingsNotifier, AsyncValue<void>>((ref) {
  return SystemSettingsNotifier(ref.watch(adminRepositoryProvider), ref);
});

// User Management Actions Notifier
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final Ref _ref;

  UserManagementNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateStatus(String userId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUserStatus(userId, newStatus);
      _ref.invalidate(paginatedUsersProvider);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(memberStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> suspendUser(String userId, [String? reason]) => updateStatus(userId, 'suspended');
  Future<void> activateUser(String userId, [String? reason]) => updateStatus(userId, 'active');

  Future<void> deleteAccount(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteUserAccount(userId);
      _ref.invalidate(paginatedUsersProvider);
      _ref.invalidate(dashboardStatsProvider);
      _ref.invalidate(memberStatsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteUserAccount(String userId) => deleteAccount(userId);
}

final userManagementActionProvider = StateNotifierProvider<UserManagementNotifier, AsyncValue<void>>((ref) {
  return UserManagementNotifier(ref.watch(adminRepositoryProvider), ref);
});

// Admin Clubs List Provider
final adminClubsProvider = FutureProvider<List<Club>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final data = await SupabaseConfig.client
      .from('club_list_view')
      .select()
      .order('name', ascending: true);
  return (data as List).map((e) => Club.fromJson(e)).toList();
});

// Admin Executives List Provider
final adminExecutivesListProvider = FutureProvider<List<ClubExecutive>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final response = await SupabaseConfig.client
      .from('club_executives_view')
      .select()
      .order('full_name', ascending: true);
  return (response as List).map((e) => ClubExecutive.fromJson(e)).toList();
});

// Admin Events List Provider
final adminEventsListProvider = FutureProvider<List<Event>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final data = await SupabaseConfig.client
      .from('event_list_view')
      .select()
      .order('event_date', ascending: false);
  return (data as List).map((e) => Event.fromJson(e)).toList();
});

