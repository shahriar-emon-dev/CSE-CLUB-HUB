import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/forum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return [];

  final userId = SupabaseConfig.currentUserId;
  if (userId == null) return [];

  final channelName = 'public:notifications:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List).map((n) => AppNotification.fromJson(n)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('ClubHub', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
            onPressed: () => context.push(AppRoutes.search),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: AppColors.primary),
                onPressed: () {},
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.05), height: 1),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -200, right: -200,
            child: Container(
              width: 600, height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.08), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.secondary.withValues(alpha: 0.05), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          notifAsync.when(
            loading: () => _buildShimmerLoading(),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            data: (notifications) {
              if (notifications.isEmpty) {
                return _buildEmptyState(context);
              }
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerDark,
                onRefresh: () async => ref.refresh(notificationsProvider.future),
                child: _buildListState(context, ref, notifications),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large Floating Icon
            SizedBox(
              width: 140, height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 40)],
                    ),
                  ),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131F).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Center(
                          child: Icon(Icons.notifications_off_outlined, size: 50, color: AppColors.primary.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.bolt, color: AppColors.secondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('All caught up!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text(
              'Check back later for updates from your favorite clubs, upcoming events, and exclusive studio announcements.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              icon: const Icon(Icons.explore, size: 20),
              label: const Text('Explore Clubs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () => context.go(AppRoutes.clubs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListState(BuildContext context, WidgetRef ref, List<AppNotification> notifications) {
    // Separate into Today and Earlier
    final now = DateTime.now();
    final todayNotifs = <AppNotification>[];
    final earlierNotifs = <AppNotification>[];

    for (var n in notifications) {
      if (now.difference(n.createdAt).inDays == 0 && now.day == n.createdAt.day) {
        todayNotifs.add(n);
      } else {
        earlierNotifs.add(n);
      }
    }

    final hasUnread = notifications.any((n) => !n.isRead);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Stay updated with your club activities', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
              InkWell(
                onTap: hasUnread ? () async {
                  final userId = SupabaseConfig.currentUserId!;
                  await SupabaseConfig.client.from('notifications')
                      .update({'is_read': true}).eq('user_id', userId);
                  ref.invalidate(notificationsProvider);
                } : null,
                child: Text(
                  hasUnread ? 'Mark all as read' : 'All read',
                  style: TextStyle(
                    color: hasUnread ? AppColors.primary : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.bold,
                    decoration: hasUnread ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          if (todayNotifs.isNotEmpty) ...[
            _buildSectionHeader('Today'),
            const SizedBox(height: 16),
            ...todayNotifs.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotifTile(notif: n, ref: ref),
            )),
            const SizedBox(height: 24),
          ],
          
          if (earlierNotifs.isNotEmpty) ...[
            _buildSectionHeader('Earlier'),
            const SizedBox(height: 16),
            ...earlierNotifs.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotifTile(notif: n, ref: ref),
            )),
          ],
          
          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(width: 16),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surfaceVariantDark,
            highlightColor: AppColors.surfaceContainerDark,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final WidgetRef ref;
  
  const _NotifTile({required this.notif, required this.ref});

  IconData get _icon {
    switch (notif.type) {
      case 'new_event': return Icons.event_available;
      case 'blog_approved': return Icons.article;
      case 'new_notice': return Icons.campaign;
      case 'new_comment': return Icons.chat_bubble;
      case 'member_approved': return Icons.workspace_premium;
      case 'rsvp_confirmed': return Icons.event_available;
      default: return Icons.notifications;
    }
  }

  Color get _color {
    switch (notif.type) {
      case 'new_event': return AppColors.secondary;
      case 'blog_approved': return AppColors.tertiaryContainer;
      case 'new_notice': return AppColors.primary;
      case 'member_approved': return AppColors.tertiary;
      default: return AppColors.textSecondaryDark;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await SupabaseConfig.client.from('notifications').delete().eq('id', notif.id);
        ref.invalidate(notificationsProvider);
      },
      child: InkWell(
        onTap: () async {
          if (!notif.isRead) {
            await SupabaseConfig.client.from('notifications')
                .update({'is_read': true}).eq('id', notif.id);
            ref.invalidate(notificationsProvider);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notif.isRead ? AppColors.surfaceContainerDark : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: notif.isRead ? [] : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20)],
          ),
          child: Stack(
            children: [
              if (!notif.isRead)
                Positioned(
                  left: -20, top: -20, bottom: -20,
                  child: Container(width: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(color: notif.isRead ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 6, left: 8),
                                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 8)]),
                              ),
                          ],
                        ),
                        if (notif.body != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            notif.body!,
                            style: TextStyle(color: notif.isRead ? AppColors.textSecondaryDark : Colors.white.withValues(alpha: 0.9), fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(_timeAgo(notif.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
