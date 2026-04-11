import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/primary_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = authState.role;
    final requestedExecutive = authState.profile?.roleRequest ?? false;

    final roleLabel = switch (role) {
      AppUserRole.admin => 'Admin',
      AppUserRole.executive => 'Executive',
      AppUserRole.student => 'Student',
    };

    final canCreate =
        role == AppUserRole.executive || role == AppUserRole.admin;
    final isAdmin = role == AppUserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('CSE Club Hub')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${user?.email ?? 'Student'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: $roleLabel',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  canCreate
                      ? 'Create actions are enabled for your account.'
                      : 'You have student-level access.',
                  textAlign: TextAlign.center,
                ),
                if (requestedExecutive && role == AppUserRole.student) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Executive request is pending admin approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Admin controls are enabled. Open admin dashboard to manage requests.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Logout',
                  isLoading: authState.isLoading,
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.cta,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
