import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/notice.dart';

final albumPhotosProvider = FutureProvider.family<List<GalleryPhoto>, String>((ref, albumId) async {
  final data = await SupabaseConfig.client
      .from('gallery_photos')
      .select()
      .eq('album_id', albumId)
      .order('created_at', ascending: false);
  return (data as List).map((p) => GalleryPhoto.fromJson(p)).toList();
});

final albumProvider = FutureProvider.family<GalleryAlbum?, String>((ref, albumId) async {
  final data = await SupabaseConfig.client
      .from('gallery_albums')
      .select()
      .eq('id', albumId)
      .maybeSingle();
  if (data == null) return null;
  return GalleryAlbum.fromJson(data);
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumProvider(albumId));
    final photosAsync = ref.watch(albumPhotosProvider(albumId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: albumAsync.whenOrNull(data: (a) => Text(a?.title ?? 'Album')) ?? const Text('Album'),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_outlined, size: 64, color: AppColors.textTertiaryDark),
                  SizedBox(height: 16),
                  Text('No photos in this album yet', style: TextStyle(color: AppColors.textSecondaryDark)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _showPhoto(context, photos, i),
              child: Image.network(photos[i].url, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _showPhoto(BuildContext context, List<GalleryPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photos.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(photos[i].url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 16, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
