import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor = AppColors.cta,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 150;

        final iconBox = tight ? 36.0 : 40.0;
        final iconSize = tight ? 18.0 : 20.0;
        final valueSize = tight ? 20.0 : 22.0;
        final labelSize = tight ? 12.0 : 13.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: tight ? 10 : 12,
            vertical: tight ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                accentColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? Icons.insights_outlined,
                  size: iconSize,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
