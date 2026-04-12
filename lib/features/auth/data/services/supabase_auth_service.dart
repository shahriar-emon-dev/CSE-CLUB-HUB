import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/user_profile.dart';

class SupabaseAuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  // Purpose: Convert low-level PostgREST errors into actionable user-facing messages.
  String _mapPostgrestError(PostgrestException error) {
    // Why: RLS recursion produces a raw JSON-ish DB error that confuses end users.
    if (error.code == '42P17') {
      return 'Profile permission rules are misconfigured. Apply the latest Supabase migration and try again.';
    }

    final message = error.message.trim();
    if (message.isNotEmpty) return message;
    return 'Database request failed. Please try again.';
  }

  Stream<User?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  Future<UserProfile?> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select('id, email, role, role_request, full_name, student_id, batch, section, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromMap(data);
    } on PostgrestException catch (error) {
      throw AppException(_mapPostgrestError(error));
    } catch (_) {
      throw const AppException('Unable to load profile right now.');
    }
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String studentId,
    required String batch,
    required String section,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const AppException('No active session found. Please login again.');
    }

    try {
      await _client.from('profiles').update({
        'full_name': fullName,
        'student_id': studentId,
        'batch': batch,
        'section': section,
      }).eq('id', user.id);
    } on PostgrestException catch (error) {
      throw AppException(_mapPostgrestError(error));
    } catch (_) {
      throw const AppException('Unable to save profile. Please retry.');
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required bool requestExecutiveAccess,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final profile = <String, dynamic>{
          'id': user.id,
          'email': email,
          'role': 'student',
          'role_request': requestExecutiveAccess,
        };

        await _client.from('profiles').upsert(profile);
      }
    } on AuthException catch (error) {
      throw AppException(error.message);
    } on PostgrestException catch (error) {
      throw AppException(_mapPostgrestError(error));
    } catch (_) {
      throw const AppException('Unable to complete signup. Please try again.');
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AppException(error.message);
    } catch (_) {
      throw const AppException('Unable to login. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AppException(error.message);
    } catch (_) {
      throw const AppException('Unable to logout right now. Please retry.');
    }
  }
}
