import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/club_posts_provider.dart';
import '../providers/clubs_provider.dart';

class CreateClubPostDialog extends ConsumerStatefulWidget {
  final String clubId;
  final String clubSlug;

  const CreateClubPostDialog({
    super.key,
    required this.clubId,
    required this.clubSlug,
  });

  @override
  ConsumerState<CreateClubPostDialog> createState() => _CreateClubPostDialogState();
}

class _CreateClubPostDialogState extends ConsumerState<CreateClubPostDialog> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  bool _isPinned = false;
  Uint8List? _imageBytes;
  String? _imageExtension;
  String? _imageFileName;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    setState(() {
      _imageBytes = bytes;
      _imageExtension = ext;
      _imageFileName = picked.name;
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    await ref.read(createClubPostNotifierProvider.notifier).createPost(
      clubId: widget.clubId,
      content: content,
      imageBytes: _imageBytes,
      imageExtension: _imageExtension,
      isPinned: _isPinned,
    );

    if (!mounted) return;

    final state = ref.read(createClubPostNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: ${state.error}', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ref.invalidate(clubPostsProvider(widget.clubId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast sent!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubDetailProvider(widget.clubSlug));
    final isLoading = ref.watch(createClubPostNotifierProvider).isLoading;
    final hasContent = _contentController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 672),
        decoration: BoxDecoration(
          color: const Color(0xFF13131F).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: -10,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0x662B1C16),
                    border: Border(left: BorderSide(color: Color(0xFFFF6A00), width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.hub, color: Color(0xFFFF6A00), size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'POSTING AS',
                                style: TextStyle(
                                  color: Color(0xFFE2BFB0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              clubAsync.when(
                                data: (club) => Text(
                                  club?.name ?? 'Unknown Club',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB694),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                loading: () => const Text('Loading...', style: TextStyle(color: Color(0xFFFFB694))),
                                error: (e, st) => const Text('Error', style: TextStyle(color: Color(0xFFFFB694))),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE2BFB0)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 5,
                        style: const TextStyle(color: Color(0xFFF8DDD2), fontSize: 18),
                        decoration: InputDecoration(
                          hintText: "What's happening in the hub?",
                          hintStyle: TextStyle(color: const Color(0xFFE2BFB0).withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: const Color(0xFF0D0D14),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: const Color(0xFF5A4136).withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: const Color(0xFF5A4136).withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: const Color(0xFFFF6A00).withValues(alpha: 0.5)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      if (_imageBytes != null) _buildFilledMediaPreview() else _buildEmptyMediaPreview(),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: const Color(0xFF5A4136).withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildUtilityButton(Icons.add_photo_alternate, 'Add Image', _pickImage),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Pin this post',
                                      style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 12),
                                    Switch(
                                      value: _isPinned,
                                      onChanged: (val) => setState(() => _isPinned = val),
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: const Color(0xFFFF6A00),
                                      inactiveThumbColor: const Color(0xFFE2BFB0),
                                      inactiveTrackColor: const Color(0xFF41312A),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                ElevatedButton(
                                  onPressed: (hasContent && !isLoading) ? _submitPost : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6A00),
                                    foregroundColor: const Color(0xFF571F00),
                                    disabledBackgroundColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                    elevation: hasContent ? 8 : 0,
                                    shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Color(0xFF571F00), strokeWidth: 2),
                                        )
                                      : const Row(
                                          children: [
                                            Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 8),
                                            Icon(Icons.send, size: 20),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMediaPreview() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF41312A).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5A4136).withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Color(0xFFE2BFB0), size: 32),
            SizedBox(height: 8),
            Text('Add Media', style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledMediaPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A4136).withValues(alpha: 0.1)),
        image: DecorationImage(
          image: MemoryImage(_imageBytes!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() {
                  _imageBytes = null;
                  _imageExtension = null;
                  _imageFileName = null;
                }),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFFFFB694), size: 20),
                const SizedBox(width: 8),
                Text(
                  _imageFileName ?? 'Attached image',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFFFFB694), size: 24),
          ),
        ),
      ),
    );
  }
}
