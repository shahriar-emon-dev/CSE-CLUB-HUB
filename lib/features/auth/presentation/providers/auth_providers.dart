import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/supabase_auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_notifier.dart';
import '../state/auth_state.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthService(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(supabaseAuthServiceProvider);
  return AuthRepositoryImpl(service);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
