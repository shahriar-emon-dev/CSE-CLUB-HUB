import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Purpose: Gives auth screens a consistent visual identity without needing asset changes.
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMiddle,
                AppColors.gradientEnd,
              ],
            ),
          ),
          child: const Icon(
            Icons.hub_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
