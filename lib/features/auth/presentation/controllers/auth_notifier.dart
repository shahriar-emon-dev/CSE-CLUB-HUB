import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../state/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(AuthState.initial()) {
    _initialize();
  }

  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  Future<void> _initialize() async {
    await _syncSession(_repository.currentUser);

    _authSubscription = _repository.authStateChanges().listen((user) async {
      await _syncSession(user);
    });
  }

  Future<void> _syncSession(User? user) async {
    if (user == null) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearProfile: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, user: user, clearError: true);

    try {
      final profile = await _repository.fetchMyProfile();
      state = state.copyWith(
        isLoading: false,
        user: user,
        profile: profile,
        clearError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load your profile.',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required bool requestExecutiveAccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        requestExecutiveAccess: requestExecutiveAccess,
      );
      state = state.copyWith(isLoading: false);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error during signup.',
      );
    }
  }

  Future<void> completeProfile({
    required String fullName,
    required String studentId,
    required String batch,
    required String section,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateMyProfile(
        fullName: fullName,
        studentId: studentId,
        batch: batch,
        section: section,
      );

      final profile = await _repository.fetchMyProfile();
      state = state.copyWith(isLoading: false, profile: profile, clearError: true);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to complete your profile right now.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error during login.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.signOut();
      state = state.copyWith(isLoading: false, clearUser: true, clearProfile: true);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error during logout.',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
