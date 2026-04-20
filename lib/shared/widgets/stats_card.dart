import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// STATS CARD WIDGET
// ==========================================
// Why: The card appears in responsive grids where height can shrink on
// small screens, so every child must be flexible and ellipsized.
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
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactMode =
              constraints.maxHeight.isFinite && constraints.maxHeight < 118;

          final contentPadding = compactMode ? 10.0 : 14.0;
          final iconBoxSize = compactMode ? 28.0 : 38.0;
          final iconSize = compactMode ? 16.0 : 20.0;
          final valueFontSize = compactMode ? 18.0 : 22.0;
          final labelFontSize = compactMode ? 12.0 : 13.0;

          return Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null)
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: iconSize),
                  )
                else
                  SizedBox(width: iconBoxSize, height: iconBoxSize),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
