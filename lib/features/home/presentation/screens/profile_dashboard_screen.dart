import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class ProfileDashboardScreen extends ConsumerWidget {
  const ProfileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppHeader(
            title: 'My Profile',
            subtitle: 'View and update your personal information.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${profile?.fullName ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Student ID: ${profile?.studentId ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Batch: ${profile?.batch ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Section: ${profile?.section ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('Email: ${profile?.email ?? authState.user?.email ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: const [
              _ProfileStatCard(title: 'Posts', value: '0'),
              _ProfileStatCard(title: 'Events', value: '0'),
              _ProfileStatCard(title: 'Following Clubs', value: '0'),
              _ProfileStatCard(title: 'Notifications', value: '0'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Logout',
            isLoading: authState.isLoading,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Profile editing UI is ready to connect with existing profile update logic.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
