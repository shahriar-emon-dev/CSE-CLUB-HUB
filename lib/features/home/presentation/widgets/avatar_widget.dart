import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ==========================================
// AVATAR WIDGET
// ==========================================

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    required this.fallbackLabel,
    this.imageUrl,
    this.size = 52,
    this.backgroundColor,
    super.key,
  });

  final String fallbackLabel;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        fallbackLabel,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
