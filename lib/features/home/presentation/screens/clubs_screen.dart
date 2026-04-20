import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/club_card.dart';
import '../widgets/clubs_grid.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/search_bar_widget.dart';

class _ClubUiItem {
  const _ClubUiItem({
    required this.id,
    required this.name,
    required this.category,
    required this.memberCount,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final int memberCount;
  final IconData icon;
}

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow({
    required String clubId,
    required bool isFollowing,
    required String clubName,
  }) async {
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId == null) return;

    if (isFollowing) {
      final shouldUnfollow = await showConfirmActionDialog(
        context,
        title: 'Unfollow this club?',
        message: 'You will no longer see $clubName in your personalized feed.',
        confirmLabel: 'Unfollow',
        isDestructive: true,
      );

      if (shouldUnfollow != true) return;

      await _client
          .from('user_club_follows')
          .delete()
          .eq('user_id', userId)
          .eq('club_id', clubId);
      return;
    }

    await _client.from('user_club_follows').upsert({
      'user_id': userId,
      'club_id': clubId,
    });
  }

  Future<void> _showClubEditor({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final focusController = TextEditingController(text: existing?['bio']?.toString() ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Create Club' : 'Edit Club',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Club Name',
                    hintText: 'Enter club name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: focusController,
                  decoration: const InputDecoration(
                    labelText: 'Focus Area',
                    hintText: 'AI, Security, Web, etc.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter club description',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final focus = focusController.text.trim();
                          final description = descriptionController.text.trim();

                          if (name.isEmpty || description.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Name and description are required.')),
                            );
                            return;
                          }

                          if (existing == null) {
                            await _client.from('clubs').insert({
                              'slug': _slugify(name),
                              'name': name,
                              'description': description,
                              'bio': focus,
                              'is_active': true,
                            });
                          } else {
                            await _client.from('clubs').update({
                              'name': name,
                              'description': description,
                              'bio': focus,
                            }).eq('id', existing['id']);
                          }

                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(existing == null ? 'Create' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    focusController.dispose();
  }

  Future<void> _deleteClub(Map<String, dynamic> club) async {
    final shouldDelete = await showConfirmActionDialog(
      context,
      title: 'Delete this club?',
      message: 'This will remove ${club['name']} and related records from active use.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (shouldDelete != true) return;

    await _client.from('clubs').delete().eq('id', club['id']);
  }

  IconData _iconForClub(String name) {
    final options = <IconData>[
      Icons.memory_outlined,
      Icons.emoji_events_outlined,
      Icons.precision_manufacturing_outlined,
      Icons.public_outlined,
      Icons.developer_mode_outlined,
      Icons.security_outlined,
    ];

    return options[name.hashCode.abs() % options.length];
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.role;
    final isAdmin = role == AppUserRole.admin;
    final userId = authState.user?.id;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientMiddle,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'All Clubs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (isAdmin)
                              OutlinedButton.icon(
                                onPressed: () => _showClubEditor(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('New Club'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SearchBarWidget(
                          controller: _searchController,
                          hintText: 'Search clubs...',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _client
                          .from('club_with_followers')
                          .stream(primaryKey: const ['id'])
                          .eq('is_active', true)
                          .order('name', ascending: true),
                      builder: (context, clubsSnapshot) {
                        final clubsRows = clubsSnapshot.data ?? const <Map<String, dynamic>>[];
                        final query = _searchController.text.trim().toLowerCase();

                        final clubs = clubsRows
                            .map((row) {
                              final map = Map<String, dynamic>.from(row);
                              return _ClubUiItem(
                                id: map['id'].toString(),
                                name: map['name']?.toString() ?? 'Club',
                                category: (map['bio']?.toString().trim().isNotEmpty ?? false)
                                    ? map['bio'].toString()
                                    : (map['description']?.toString() ?? ''),
                                memberCount: ((map['follower_count'] as num?)?.toInt() ?? 0),
                                icon: _iconForClub(map['name']?.toString() ?? 'Club'),
                              );
                            })
                            .where((club) {
                              return query.isEmpty ||
                                  club.name.toLowerCase().contains(query) ||
                                  club.category.toLowerCase().contains(query);
                            })
                            .toList();

                        if (clubs.isEmpty) {
                          return const EmptyState(
                            title: 'No clubs found',
                            message: 'Try another keyword or create a new club from admin controls.',
                          );
                        }

                        if (userId == null) {
                          return ClubsGrid(
                            isLoading: clubsSnapshot.connectionState == ConnectionState.waiting,
                            itemCount: clubs.length,
                            itemBuilder: (context, index) {
                              final club = clubs[index];
                              return ClubCard(
                                name: club.name,
                                category: club.category,
                                memberCount: club.memberCount,
                                icon: club.icon,
                                isFollowing: false,
                                onTap: () => context.push(AppRoutes.clubProfile),
                                onFollowToggle: () {},
                              );
                            },
                          );
                        }

                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _client
                              .from('user_club_follows')
                              .stream(primaryKey: const ['user_id', 'club_id'])
                              .eq('user_id', userId),
                          builder: (context, followsSnapshot) {
                            final follows = followsSnapshot.data ?? const <Map<String, dynamic>>[];
                            final followedIds = follows
                                .map((row) => row['club_id']?.toString())
                                .whereType<String>()
                                .toSet();

                            return ClubsGrid(
                              isLoading: clubsSnapshot.connectionState == ConnectionState.waiting,
                              itemCount: clubs.length,
                              itemBuilder: (context, index) {
                                final club = clubs[index];
                                final isFollowing = followedIds.contains(club.id);

                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClubCard(
                                        name: club.name,
                                        category: club.category,
                                        memberCount: club.memberCount,
                                        icon: club.icon,
                                        isFollowing: isFollowing,
                                        onTap: () => context.push(AppRoutes.clubProfile),
                                        onFollowToggle: () => _toggleFollow(
                                          clubId: club.id,
                                          isFollowing: isFollowing,
                                          clubName: club.name,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                                          color: Colors.white,
                                          onSelected: (value) {
                                            final row = clubsRows.firstWhere(
                                              (r) => r['id'].toString() == club.id,
                                            );

                                            if (value == 'edit') {
                                              _showClubEditor(existing: Map<String, dynamic>.from(row));
                                            } else if (value == 'delete') {
                                              _deleteClub(Map<String, dynamic>.from(row));
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNav(
        activeRoute: AppRoutes.clubs,
      ),
    );
  }
}
