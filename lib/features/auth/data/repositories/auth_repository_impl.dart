import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/supabase_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final SupabaseAuthService _service;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Stream<User?> authStateChanges() => _service.authStateChanges();

  @override
  Future<UserProfile?> fetchMyProfile() {
    return _service.fetchMyProfile();
  }

  @override
  Future<void> updateMyProfile({
    required String fullName,
    required String studentId,
    required String batch,
    required String section,
    required String department,
  }) {
    return _service.updateMyProfile(
      fullName: fullName,
      studentId: studentId,
      batch: batch,
      section: section,
      department: department,
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _service.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _service.signOut();
  }

  @override
  Future<void> requestExecutiveAccess() {
    return _service.requestExecutiveAccess();
  }

  @override
  Future<void> withdrawExecutiveRequest() {
    return _service.withdrawExecutiveRequest();
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _service.signUpWithEmail(
      email: email,
      password: password,
    );
  }
}
