import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

final membersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final channelName = 'public:profiles';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('is_approved', true)
      .neq('role', 'banned')
      .order('full_name');
  return (data as List).map((p) => UserProfile.fromJson(p)).toList();
});

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';


  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text(AppStrings.memberDirectory)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      })
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                final filtered = members.where((m) {
                  final nameMatch = m.fullName.toLowerCase().contains(_searchQuery);
                  final idMatch = m.studentId?.toLowerCase().contains(_searchQuery) ?? false;
                  return nameMatch || idMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No members found', style: TextStyle(color: AppColors.textSecondaryDark)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _MemberTile(member: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UserProfile member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/members/${member.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              child: member.avatarUrl == null
                  ? Text(member.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName, style: Theme.of(context).textTheme.titleLarge),
                  Row(
                    children: [
                      if (member.studentId != null) Text('ID: ${member.studentId}', style: Theme.of(context).textTheme.bodySmall),
                      if (member.batch != null) ...[
                        const Text(' · ', style: TextStyle(color: AppColors.textSecondaryDark)),
                        Text('Batch ${member.batch}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.isAdmin
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: member.isAdmin
                      ? AppColors.accent
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
