import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/feed_repository.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

const _feedTabPrefKey = 'feed_selected_tab';

// ==========================================
// LIBRARY AND DEPENDENCY IMPORTS
// ==========================================

enum FeedTab {
  following,
  allClubs,
}

class FeedState {
  const FeedState({
    required this.isLoading,
    required this.followedClubCount,
    required this.selectedTab,
    required this.rows,
    this.error,
  });

  factory FeedState.initial() => const FeedState(
        isLoading: true,
        followedClubCount: 0,
        selectedTab: FeedTab.allClubs,
        rows: <Map<String, dynamic>>[],
      );

  final bool isLoading;
  final int followedClubCount;
  final FeedTab selectedTab;
  final List<Map<String, dynamic>> rows;
  final String? error;

  bool get showTabbedInterface => followedClubCount >= 1;
  bool get showGlobalOnly => followedClubCount == 0;

  FeedState copyWith({
    bool? isLoading,
    int? followedClubCount,
    FeedTab? selectedTab,
    List<Map<String, dynamic>>? rows,
    String? error,
    bool clearError = false,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      followedClubCount: followedClubCount ?? this.followedClubCount,
      selectedTab: selectedTab ?? this.selectedTab,
      rows: rows ?? this.rows,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(this._repository) : super(FeedState.initial()) {
    initialize();
  }

  final FeedRepository _repository;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final followedCount = await _repository.getFollowedClubCount();
      final storedTab = await _loadSelectedTab();

      final selectedTab = followedCount == 0 ? FeedTab.allClubs : storedTab;
      final mode = selectedTab == FeedTab.following ? 'personalized' : 'global';
      final rows = await _repository.getHomeFeed(mode: mode);

      state = state.copyWith(
        isLoading: false,
        followedClubCount: followedCount,
        selectedTab: selectedTab,
        rows: rows,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feed.',
      );
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> selectTab(FeedTab tab) async {
    if (state.followedClubCount == 0 && tab == FeedTab.following) {
      return;
    }

    state = state.copyWith(isLoading: true, selectedTab: tab, clearError: true);

    try {
      await _persistSelectedTab(tab);
      await _repository.setFeedPreference(
        tab == FeedTab.following ? 'personalized' : 'global',
      );

      final rows = await _repository.getHomeFeed(
        mode: tab == FeedTab.following ? 'personalized' : 'global',
      );

      state = state.copyWith(
        isLoading: false,
        rows: rows,
        selectedTab: tab,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to change feed tab right now.',
      );
    }
  }

  Future<FeedTab> _loadSelectedTab() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_feedTabPrefKey);
    if (raw == FeedTab.following.name) return FeedTab.following;
    return FeedTab.allClubs;
  }

  Future<void> _persistSelectedTab(FeedTab tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedTabPrefKey, tab.name);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedNotifier(repository);
});
