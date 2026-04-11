import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    this.user,
    this.profile,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(isLoading: true);

  final bool isLoading;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
  bool get needsProfileSetup => isAuthenticated && !(profile?.isComplete ?? false);
  AppUserRole get role => profile?.role ?? AppUserRole.student;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    bool clearUser = false,
    UserProfile? profile,
    bool clearProfile = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
