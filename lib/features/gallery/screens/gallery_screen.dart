import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/notice.dart';

final galleryAlbumsProvider = FutureProvider<List<GalleryAlbum>>((ref) async {
  final data = await SupabaseConfig.client
      .from('gallery_albums')
      .select()
      .order('created_at', ascending: false);
  return (data as List).map((a) => GalleryAlbum.fromJson(a)).toList();
});

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(galleryAlbumsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text(AppStrings.gallery)),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (albums) {
          if (albums.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textTertiaryDark),
                  SizedBox(height: 16),
                  Text(AppStrings.noAlbums, style: TextStyle(color: AppColors.textSecondaryDark)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) => _AlbumCard(album: albums[i]),
          );
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final GalleryAlbum album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/gallery/${album.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: album.coverUrl != null
                    ? Image.network(album.coverUrl!, fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                        ),
                        child: const Icon(Icons.photo, size: 40, color: Colors.white54),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.title, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (album.description != null)
                    Text(album.description!, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
