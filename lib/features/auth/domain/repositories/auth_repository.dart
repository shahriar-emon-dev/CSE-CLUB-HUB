import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/user_profile.dart';

abstract class AuthRepository {
  User? get currentUser;

  Stream<User?> authStateChanges();

  Future<UserProfile?> fetchMyProfile();

  Future<void> updateMyProfile({
    required String fullName,
    required String studentId,
    required String batch,
    required String section,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required bool requestExecutiveAccess,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
