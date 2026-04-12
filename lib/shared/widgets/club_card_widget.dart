import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class ClubCardWidget extends StatelessWidget {
  const ClubCardWidget({
    required this.name,
    required this.description,
    required this.onTap,
    this.isFollowing = false,
    this.onFollowToggle,
    super.key,
  });

  final String name;
  final String description;
  final VoidCallback onTap;
  final bool isFollowing;
  final VoidCallback? onFollowToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_2_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onFollowToggle,
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
