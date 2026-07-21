import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';

/// Shimmer skeleton shown while the initial feed page is loading, shaped
/// like the real layout (discovery row + a couple of post-card placeholders)
/// instead of a generic spinner.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.white.withValues(alpha: 0.09),
      period: const Duration(milliseconds: 1400),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _box(width: 148, height: 172, radius: 20),
                )),
          ),
          const SizedBox(height: 24),
          _box(width: double.infinity, height: 132, radius: 24),
          const SizedBox(height: 24),
          _postCardSkeleton(),
          const SizedBox(height: 16),
          _postCardSkeleton(),
        ],
      ),
    );
  }

  Widget _postCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 42, height: 42, radius: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 120, height: 12, radius: 6),
                    const SizedBox(height: 6),
                    _box(width: 80, height: 10, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _box(width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 8),
          _box(width: 220, height: 12, radius: 6),
          const SizedBox(height: 16),
          _box(width: double.infinity, height: 180, radius: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              _box(width: 60, height: 24, radius: 12),
              const SizedBox(width: 10),
              _box(width: 60, height: 24, radius: 12),
              const SizedBox(width: 10),
              _box(width: 60, height: 24, radius: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box({required double width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
