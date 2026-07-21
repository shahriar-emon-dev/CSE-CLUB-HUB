import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/notice.dart';
import 'post_actions_bottom_sheet.dart';

class PinnedPostCard extends StatelessWidget {
  final Notice notice;
  final bool showActions;

  const PinnedPostCard({
    super.key,
    required this.notice,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1311),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24, right: -24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.push_pin, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Pinned', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.campaign, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Text(DateFormat('MMM d, yyyy').format(notice.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  if (showActions)
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark),
                      onPressed: () => showPostActions(context, postId: notice.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(notice.title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(notice.body, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.share, color: AppColors.textSecondaryDark, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
