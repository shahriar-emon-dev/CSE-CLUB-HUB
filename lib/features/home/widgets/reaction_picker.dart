import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A floating reaction picker that appears on long-press.
/// Shows Like (❤️), Fire (🔥), Clap (👏) with bouncy scale-in animation.
class ReactionPicker extends StatefulWidget {
  final String? currentReaction;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionPicker({
    super.key,
    this.currentReaction,
    required this.onReactionSelected,
    required this.onDismiss,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReactionOption(
              emoji: '❤️',
              label: 'Like',
              type: 'favorite',
              color: const Color(0xFFFF4757),
            ),
            const SizedBox(width: 4),
            _buildReactionOption(
              emoji: '🔥',
              label: 'Fire',
              type: 'fire',
              color: const Color(0xFFFF6B35),
            ),
            const SizedBox(width: 4),
            _buildReactionOption(
              emoji: '👏',
              label: 'Clap',
              type: 'pan_tool',
              color: const Color(0xFFFFD93D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionOption({
    required String emoji,
    required String label,
    required String type,
    required Color color,
  }) {
    final isActive = widget.currentReaction == type;

    return GestureDetector(
      onTap: () {
        widget.onReactionSelected(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: isActive ? 28 : 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : AppColors.textSecondaryDark,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the reaction picker as an overlay at the given position.
void showReactionPicker(
  BuildContext context, {
  required GlobalKey anchorKey,
  required String? currentReaction,
  required ValueChanged<String> onReactionSelected,
}) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Dismiss layer
        Positioned.fill(
          child: GestureDetector(
            onTap: () => overlayEntry.remove(),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Picker positioned above the anchor
        Positioned(
          left: position.dx - 40,
          top: position.dy - 90,
          child: ReactionPicker(
            currentReaction: currentReaction,
            onReactionSelected: (type) {
              overlayEntry.remove();
              onReactionSelected(type);
            },
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ],
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

/// Returns icon data for a reaction type
IconData getReactionIcon(String type, {bool filled = false}) {
  switch (type) {
    case 'favorite':
      return filled ? Icons.favorite : Icons.favorite_border;
    case 'fire':
      return filled
          ? Icons.local_fire_department
          : Icons.local_fire_department_outlined;
    case 'pan_tool':
    case 'hand':
      return filled ? Icons.front_hand : Icons.front_hand_outlined;
    default:
      return Icons.thumb_up_outlined;
  }
}

/// Returns color for a reaction type
Color getReactionColor(String type) {
  switch (type) {
    case 'favorite':
      return const Color(0xFFFF4757);
    case 'fire':
      return const Color(0xFFFF6B35);
    case 'pan_tool':
    case 'hand':
      return const Color(0xFFFFD93D);
    default:
      return AppColors.textSecondaryDark;
  }
}
