import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ==========================================
// CLUB CARD WIDGET
// ==========================================

class ClubCard extends StatefulWidget {
  const ClubCard({
    required this.name,
    required this.category,
    required this.memberCount,
    required this.icon,
    required this.isFollowing,
    required this.onTap,
    required this.onFollowToggle,
    super.key,
  });

  final String name;
  final String category;
  final int memberCount;
  final IconData icon;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  @override
  State<ClubCard> createState() => _ClubCardState();
}

class _ClubCardState extends State<ClubCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final showHover = kIsWeb;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(
          showHover && _isHovered ? 1.01 : 1.0,
          showHover && _isHovered ? 1.01 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: showHover && _isHovered ? 0.15 : 0.08),
              blurRadius: showHover && _isHovered ? 20 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 116,
                  color: AppColors.accent,
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_2_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.memberCount}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.isFollowing)
                        const Text(
                          'Following',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.onFollowToggle,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cta,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
