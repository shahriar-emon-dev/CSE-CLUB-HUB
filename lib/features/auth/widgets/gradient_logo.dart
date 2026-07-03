import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GradientLogo extends StatelessWidget {
  final double size;
  const GradientLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.25),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.hub_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}
