import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/user_profile.dart';
import '../../profile/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// StreamProvider that listens to Supabase authentication state changes.
/// Provides the current authenticated [User] or null if unauthenticated.
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.client.auth.onAuthStateChange.map((event) => event.session?.user);
});

/// StreamProvider that listens to the raw Supabase Session (specifically the access token).
/// Data providers should watch this to automatically invalidate and re-fetch when the JWT refreshes.
final authSessionProvider = StreamProvider<String?>((ref) {
  return SupabaseConfig.client.auth.onAuthStateChange.map((event) => event.session?.accessToken);
});

/// FutureProvider that fetches and listens in realtime to the [UserProfile] data for the currently authenticated user
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  final channel = SupabaseConfig.client
      .channel('public:rt_current_profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: user.id),
        callback: (payload) {
          ref.invalidateSelf();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'club_executives',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: user.id),
        callback: (payload) {
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  return ref.read(profileRepositoryProvider).getUserProfile(user.id);
});

// Auth actions notifier
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? studentId,
    String? batch,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_id': studentId,
          'batch': batch,
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      await SupabaseConfig.client.from('profiles').update({
        'full_name': fullName,
        'student_id': ?studentId,
        'batch': ?batch,
        'role': 'Regular Student',
      }).eq('id', response.user!.id);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseConfig.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (_) => AuthNotifier(),
);
