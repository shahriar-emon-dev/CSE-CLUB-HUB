import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/notice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final noticesProvider = FutureProvider<List<Notice>>((ref) async {
  final channelName = 'public:notices:${DateTime.now().millisecondsSinceEpoch}';
  final channel = SupabaseConfig.client.channel(channelName)
      .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notices',
          callback: (payload) {
            ref.invalidateSelf();
          })
      .subscribe();

  ref.onDispose(() {
    SupabaseConfig.client.removeChannel(channel);
  });

  final data = await SupabaseConfig.client
      .from('notices')
      .select()
      .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
      .order('is_pinned', ascending: false)
      .order('priority', ascending: false)
      .order('created_at', ascending: false);
  return (data as List).map((n) => Notice.fromJson(n)).toList();
});

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text(AppStrings.notices)),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: AppColors.textTertiaryDark),
                  const SizedBox(height: 16),
                  const Text(AppStrings.noNotices, style: TextStyle(color: AppColors.textSecondaryDark)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _NoticeCard(notice: notices[i]),
          );
        },
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  const _NoticeCard({required this.notice});

  Color get _color {
    switch (notice.category) {
      case NoticeCategory.urgent: return AppColors.error;
      case NoticeCategory.event: return AppColors.info;
      case NoticeCategory.academic: return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notice.isUrgent ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderDark),
        boxShadow: notice.isUrgent
            ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.1), blurRadius: 8)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (notice.isPinned) ...[
                        Icon(Icons.push_pin, size: 12, color: _color),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        notice.isPinned ? 'Pinned · ${notice.category.displayName}' : notice.category.displayName,
                        style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(notice.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(notice.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(notice.body, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (notice.expiresAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${DateFormat('MMM d, y').format(notice.expiresAt!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
