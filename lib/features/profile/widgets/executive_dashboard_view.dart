import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user_profile.dart';
import '../../clubs/screens/edit_club_screen.dart';
import '../providers/executive_stats_provider.dart';

class ExecutiveDashboardView extends ConsumerWidget {
  final UserProfile profile;

  const ExecutiveDashboardView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubIdAsync = ref.watch(myExecutiveClubIdProvider(profile.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: clubIdAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, st) => _ErrorState(onRetry: () => ref.invalidate(myExecutiveClubIdProvider(profile.id))),
        data: (clubId) {
          final resolvedClubId = clubId ?? profile.managedClubId;
          if (resolvedClubId == null) {
            return const _UnassignedState();
          }
          return _StatsSection(clubId: resolvedClubId, ref: ref);
        },
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  final String clubId;
  final WidgetRef ref;

  const _StatsSection({required this.clubId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final statsAsync = ref.watch(executiveClubStatsProvider(clubId));

    return statsAsync.when(
      loading: () => const _DashboardSkeleton(),
      error: (e, st) => _ErrorState(onRetry: () => ref.invalidate(executiveClubStatsProvider(clubId))),
      data: (stats) {
        if (stats == null) return const _UnassignedState();
        return _DashboardContent(stats: stats);
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final ExecutiveClubStats stats;
  const _DashboardContent({required this.stats});

  Future<void> _exportAttendance(BuildContext context) async {
    final club = stats.club;
    final buffer = StringBuffer('Club,Total Events,Total Attendees,Engagement Rate\n');
    buffer.writeln('${club.name},${stats.totalEvents},${stats.totalAttendees},${stats.engagementRate.toStringAsFixed(1)}%');
    try {
      await Share.share(buffer.toString(), subject: '${club.name} — Attendance Summary');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export attendance: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _requestAdminApproval(BuildContext context, WidgetRef ref) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return;
    try {
      await SupabaseConfig.client.from('system_activities').insert({
        'actor_id': userId,
        'action': 'admin_approval_requested',
        'entity_type': 'club',
        'entity_id': stats.club.id,
        'metadata': {'club_name': stats.club.name},
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request logged for admin review.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = stats.club;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bar — both sides are flexible so long club names can never
        // push the "ACTIVE LEADERSHIP" badge off the right edge.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXECUTIVE MANAGEMENT SUITE',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          club.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: Color(0xFF4CAF50)),
                  SizedBox(width: 6),
                  Text('ACTIVE', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 20),

        const Text('Club Performance & Analytics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Generous (near-square) ratio with text-overflow guards on every
          // label inside the card — the previous 1.6 ratio didn't leave
          // enough vertical room for 3 stacked text rows at real font sizes.
          childAspectRatio: 1.05,
          children: [
            _MetricCard(title: 'Members', value: '${club.memberCount}', icon: Icons.group, color: const Color(0xFF2196F3), subtitle: club.memberCount == 1 ? '1 follower' : '${club.memberCount} followers'),
            _MetricCard(title: 'Total Events', value: '${stats.totalEvents}', icon: Icons.calendar_month, color: const Color(0xFF4CAF50), subtitle: '${stats.upcomingEvents} upcoming'),
            _MetricCard(title: 'Total Posts', value: '${stats.totalPosts}', icon: Icons.article, color: const Color(0xFFFF9800), subtitle: 'Published'),
            _MetricCard(title: 'Attendees', value: '${stats.totalAttendees}', icon: Icons.confirmation_number, color: const Color(0xFF9C27B0), subtitle: stats.totalEvents > 0 ? 'Avg ${(stats.totalAttendees / stats.totalEvents).round()}/event' : 'No events yet'),
            _MetricCard(title: 'Engagement', value: '${stats.engagementRate.toStringAsFixed(1)}%', icon: Icons.trending_up, color: const Color(0xFFE91E63), subtitle: 'Reactions + comments'),
            _MetricCard(title: 'Waitlisted', value: '${stats.pendingRsvps}', icon: Icons.rule, color: const Color(0xFF00BCD4), subtitle: stats.pendingRsvps == 0 ? 'All caught up' : 'Awaiting capacity'),
          ],
        ),
        const SizedBox(height: 28),

        const Text('Executive Action Center', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionChip(
              icon: Icons.add_circle,
              label: 'Create Club Event',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.createEvent),
            ),
            _ActionChip(
              icon: Icons.campaign,
              label: 'Publish Announcement',
              color: const Color(0xFFFF9800),
              onTap: () => context.push(AppRoutes.createPost),
            ),
            _ActionChip(
              icon: Icons.manage_accounts,
              label: 'Manage Club Members',
              color: const Color(0xFF2196F3),
              onTap: () => context.go('/clubs/${club.slug}'),
            ),
            _ActionChip(
              icon: Icons.edit,
              label: 'Edit Club Details',
              color: const Color(0xFF9C27B0),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditClubScreen(clubSlug: club.slug))),
            ),
            _ActionChip(
              icon: Icons.fact_check,
              label: 'Review Event RSVPs',
              color: const Color(0xFF4CAF50),
              onTap: () => context.push(AppRoutes.events),
            ),
            _ActionChip(
              icon: Icons.file_download,
              label: 'Export Attendance',
              color: const Color(0xFF00BCD4),
              onTap: () => _exportAttendance(context),
            ),
            _ActionChip(
              icon: Icons.admin_panel_settings,
              label: 'Request Admin Approval',
              color: const Color(0xFFE91E63),
              onTap: () => _requestAdminApproval(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textTertiaryDark, size: 32),
        const SizedBox(height: 12),
        const Text('Could not load club stats', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _UnassignedState extends StatelessWidget {
  const _UnassignedState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXECUTIVE MANAGEMENT SUITE', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              SizedBox(height: 4),
              Text('Not yet assigned to a club', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Once an admin assigns you as a club executive, your management tools appear here.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}
