import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/club.dart';
import 'create_club_screen.dart';
import '../providers/admin_providers.dart';

class AdminClubsScreen extends ConsumerStatefulWidget {
  const AdminClubsScreen({super.key});

  @override
  ConsumerState<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends ConsumerState<AdminClubsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(adminClubsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Club Management Hub',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitor, edit, and oversee all registered student organizations and nodes across campus.',
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const CreateClubScreen()));
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create New Club'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: const Color(0xFF412D00),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search clubs by name, focus area, or description...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
                prefixIcon: const Icon(Icons.search, color: AppColors.tertiary),
                filled: true,
                fillColor: AppColors.surfaceContainerDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            clubsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(64),
                child: CircularProgressIndicator(color: AppColors.tertiary),
              )),
              error: (err, st) => Center(child: Text('Failed to load clubs: $err', style: const TextStyle(color: AppColors.error))),
              data: (clubs) {
                final filtered = clubs.where((c) =>
                  c.name.toLowerCase().contains(_searchQuery) ||
                  c.focusArea.toLowerCase().contains(_searchQuery) ||
                  (c.description ?? '').toLowerCase().contains(_searchQuery)
                ).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: Text('No clubs match your search criteria.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final club = filtered[index];
                        return _buildClubCard(club);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    Color clubColor;
    try {
      clubColor = Color(int.parse((club.colorHex ?? '#00FFFF').replaceAll('#', '0xFF')));
    } catch (_) {
      clubColor = AppColors.tertiary;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: clubColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: clubColor.withValues(alpha: 0.5)),
                  image: club.logoUrl != null && club.logoUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(club.logoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: club.logoUrl == null || club.logoUrl!.isEmpty
                    ? Icon(Icons.hub, color: clubColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: clubColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(club.focusArea, style: TextStyle(color: clubColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            club.description ?? 'No description provided.',
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: Active',
                style: const TextStyle(color: AppColors.tertiary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.textSecondaryDark, size: 20),
                    tooltip: 'Edit Club Info',
                    onPressed: () => _openEditClubDialog(club),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.clubDetail.replaceAll(':id', club.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clubColor.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEditClubDialog(Club club) {
    final nameCtrl = TextEditingController(text: club.name);
    final focusCtrl = TextEditingController(text: club.focusArea);
    final descCtrl = TextEditingController(text: club.description);
    final colorCtrl = TextEditingController(text: club.colorHex);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D100A),
        title: Text('Edit Club: ${club.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Club Name', labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: focusCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Focus Area (e.g. AI / Robotics)', labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: colorCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Color Hex (e.g. #FF7700)', labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, foregroundColor: const Color(0xFF412D00)),
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).updateClubDetails(
                  clubId: club.id,
                  name: nameCtrl.text.trim(),
                  focusArea: focusCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  colorHex: colorCtrl.text.trim(),
                );
                ref.invalidate(adminClubsProvider);
                ref.invalidate(dashboardStatsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error updating club: $e')));
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
