import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/unified_feed_item.dart';
import 'package:go_router/go_router.dart';
import 'post_actions_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventCard extends StatelessWidget {
  final UnifiedFeedItem item;
  final bool showActions;

  const EventCard({
    super.key,
    required this.item,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/events/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (item.clubId != null) {
                      context.push('/clubs/${item.clubId}');
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: item.clubLogoUrl != null && item.clubLogoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                  topRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: item.clubLogoUrl!, 
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(Icons.event, color: AppColors.secondary),
                                  errorWidget: (context, url, error) => const Icon(Icons.event, color: AppColors.secondary),
                                ),
                              )
                            : const Icon(Icons.event, color: AppColors.secondary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.clubName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Text(DateFormat('MMM d').format(item.createdAt), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              if (showActions)
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondaryDark),
                  onPressed: () => showPostActions(context, postId: item.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (item.description != null && item.description!.isNotEmpty) ...[
            Text(item.description!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
          ],
          if (item.mediaAssetUrl != null && item.mediaAssetUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.mediaAssetUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 200, color: AppColors.surfaceContainerHighDark),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Event details badge row
          if (item.eventDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(item.eventDate!),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (item.venue != null && item.venue!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.venue!,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceContainerHighDark),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildInteraction(Icons.favorite_border, item.favoriteCount.toString()),
                  const SizedBox(width: 16),
                  _buildInteraction(Icons.chat_bubble_outline, item.commentCount.toString()),
                ],
              ),
              if (item.capacity != null)
                Row(
                  children: [
                    const Icon(Icons.people, color: AppColors.textSecondaryDark, size: 16),
                    const SizedBox(width: 6),
                    Text('${item.rsvpCount ?? 0} / ${item.capacity} RSVPs', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                  ],
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInteraction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondaryDark, size: 18),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
      ],
    );
  }
}
