import 'package:flutter/material.dart';

// ==========================================
// POST IMAGE GRID WIDGET
// ==========================================

class PostImageGrid extends StatelessWidget {
  const PostImageGrid({
    required this.imageUrls,
    super.key,
  });

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            imageUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF3F4F6)),
          ),
        ),
      );
    }

    final showImages = imageUrls.length > 4 ? imageUrls.take(4).toList() : imageUrls;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: showImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = showImages[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            item,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF3F4F6)),
          ),
        );
      },
    );
  }
}
