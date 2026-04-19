import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    super.key,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? AppColors.accent.withValues(alpha: 0.12);
    final resolvedForeground = foregroundColor ?? AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedForeground.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: resolvedForeground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: resolvedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
