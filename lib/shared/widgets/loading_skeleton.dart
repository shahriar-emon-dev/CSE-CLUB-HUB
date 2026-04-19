import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.height = 120,
    this.borderRadius = 16,
    super.key,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
