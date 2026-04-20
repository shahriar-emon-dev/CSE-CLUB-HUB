import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ==========================================
// CLUBS GRID WIDGET
// ==========================================

class ClubsGrid extends StatelessWidget {
  const ClubsGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.isLoading = false,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const crossAxisCount = 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: isLoading ? 6 : itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: width < 520 ? 0.72 : 0.78,
          ),
          itemBuilder: (context, index) {
            if (isLoading) return const _ClubCardSkeleton();
            return itemBuilder(context, index);
          },
        );
      },
    );
  }
}

class _ClubCardSkeleton extends StatelessWidget {
  const _ClubCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 116,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _line(height: 16, width: double.infinity),
                const SizedBox(height: 8),
                _line(height: 12, width: 120),
                const SizedBox(height: 8),
                _line(height: 12, width: 80),
                const SizedBox(height: 14),
                _line(height: 34, width: double.infinity, radius: 999),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _line({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
