import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Sticky, animated Following / All Clubs switcher plus category chip row.
/// Wrapped in a [SliverPersistentHeader] by the caller so it pins below the
/// floating header once the discovery/featured sections scroll past it.
class FeedSwitcher extends StatelessWidget {
  final bool showFollowing;
  final ValueChanged<bool> onFollowingChanged;
  final List<String> filters;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;

  const FeedSwitcher({
    super.key,
    required this.showFollowing,
    required this.onFollowingChanged,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const double height = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark,
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = (constraints.maxWidth - 6) / 2;
                return Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: showFollowing ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          width: segmentWidth,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12)],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _SegmentLabel(
                            label: 'Following',
                            isActive: showFollowing,
                            onTap: () => onFollowingChanged(true),
                          ),
                          _SegmentLabel(
                            label: 'All Clubs',
                            isActive: !showFollowing,
                            onTap: () => onFollowingChanged(false),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = selectedFilter == index;
                return GestureDetector(
                  onTap: () => onFilterChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textTertiaryDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentLabel({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textTertiaryDark,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate that pins [FeedSwitcher] to the top of the
/// viewport once scrolled to, directly below the floating [HomeHeader].
class FeedSwitcherHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  FeedSwitcherHeaderDelegate({required this.child});

  @override
  double get minExtent => FeedSwitcher.height;

  @override
  double get maxExtent => FeedSwitcher.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant FeedSwitcherHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
