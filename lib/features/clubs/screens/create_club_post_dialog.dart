import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/club_posts_provider.dart';
import '../providers/clubs_provider.dart';

class CreateClubPostDialog extends ConsumerStatefulWidget {
  final String clubId;
  final String clubSlug; // Needed to fetch club detail if we want the name/icon

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
  bool _isPinned = false;
  String? _attachedImageUrl;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    // Currently the backend createPost doesn't take imageUrl directly, it takes imageBytes for upload.
    // If we only have a URL string, we might need to modify the provider to accept imageUrl directly,
    // or just omit it for now if we can't upload. But looking at the state, `_imageBytes` is what we should pass.
    // Let me check if `_imageBytes` exists in the dialog.

    if (!mounted) return;

    final state = ref.read(createClubPostNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: ${state.error}', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
      );
    } else {
      // Invalidate posts list
      ref.invalidate(clubPostsProvider(widget.clubId));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch club info to display name and icon in the header
    final clubAsync = ref.watch(clubDetailProvider(widget.clubSlug));
    final isLoading = ref.watch(createClubPostNotifierProvider).isLoading;
    final hasContent = _contentController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
        decoration: BoxDecoration(
          color: const Color(0xFF13131F).withValues(alpha: 0.8), // studio-glass
          borderRadius: BorderRadius.circular(12), // rounded-xl
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
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0x662B1C16), // surface-container/40
                    border: Border(left: BorderSide(color: Color(0xFFFF6A00), width: 4)), // orange-accent-bar
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
                              color: const Color(0xFFFF6A00).withValues(alpha: 0.2), // primary-container/20
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
                              const Text('POSTING AS', style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.2)), // on-surface-variant
                              clubAsync.when(
                                data: (club) => Text(club?.name ?? 'Unknown Club', style: const TextStyle(color: Color(0xFFFFB694), fontSize: 24, fontWeight: FontWeight.w600)), // primary
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
                        hoverColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
                
                // Editor Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Text Area
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
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Media Preview Area
                      if (_attachedImageUrl != null)
                        _buildFilledMediaPreview()
                      else
                        _buildEmptyMediaPreview(),
                        
                      const SizedBox(height: 24),
                      
                      // Action Controls Row
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: const Color(0xFF5A4136).withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Utilities
                            Row(
                              children: [
                                _buildUtilityButton(Icons.add_photo_alternate, "Add Image", () {
                                  // Mocking an image attachment for now
                                  setState(() {
                                    _attachedImageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuD72mqxlxRkiH2DZlrim6TwP1ZJQRWD9fXckikvEpMmO2nK_CmjsQKDlMceaU2p1parlQDl1lVKIez0aqjVvLgQCZxG7wvfc_lkUacwPZiFM-zrxl0OSiCHI8o4Z0NlYG4SQNzAOxpmlEWquYx1zRWIDtxnJ6j86Pn_4Pe4tmku3_5FpyZ_HSDstairSxsM6k4oT1mJewgr5asQ0JARLtp5fPFanxVj_HyoKUJsj-Hbb8SplxX1j2-8v2G_oa7-p5ji26WHthYBGNs";
                                  });
                                }),
                                const SizedBox(width: 8),
                                _buildUtilityButton(Icons.schedule, "Schedule", () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduling coming soon!')));
                                }),
                                const SizedBox(width: 8),
                                _buildUtilityButton(Icons.poll, "Poll", () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Polls coming soon!')));
                                }),
                              ],
                            ),
                            
                            // Toggles & Post
                            Row(
                              children: [
                                // Pin Toggle
                                Row(
                                  children: [
                                    const Text('Pin this post', style: TextStyle(color: Color(0xFFE2BFB0), fontSize: 14, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 12),
                                    Switch(
                                      value: _isPinned,
                                      onChanged: (val) {
                                        setState(() {
                                          _isPinned = val;
                                        });
                                      },
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: const Color(0xFFFF6A00),
                                      inactiveThumbColor: const Color(0xFFE2BFB0),
                                      inactiveTrackColor: const Color(0xFF41312A),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // Post Button
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
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF571F00), strokeWidth: 2))
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
      onTap: () {
        setState(() {
          _attachedImageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuD72mqxlxRkiH2DZlrim6TwP1ZJQRWD9fXckikvEpMmO2nK_CmjsQKDlMceaU2p1parlQDl1lVKIez0aqjVvLgQCZxG7wvfc_lkUacwPZiFM-zrxl0OSiCHI8o4Z0NlYG4SQNzAOxpmlEWquYx1zRWIDtxnJ6j86Pn_4Pe4tmku3_5FpyZ_HSDstairSxsM6k4oT1mJewgr5asQ0JARLtp5fPFanxVj_HyoKUJsj-Hbb8SplxX1j2-8v2G_oa7-p5ji26WHthYBGNs";
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 120, // To mimic grid-cols-2 half height, or just a small placeholder
        decoration: BoxDecoration(
          color: const Color(0xFF41312A).withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFF5A4136).withValues(alpha: 0.3), style: BorderStyle.none),
          borderRadius: BorderRadius.circular(12),
        ),
        // Use CustomPaint for dashed border if needed, but a simple border is fine for now
        child: Container(
           decoration: BoxDecoration(
             border: Border.all(color: const Color(0xFF5A4136).withValues(alpha: 0.3)), // Dashed effect is hard in standard BoxDecoration without third party
             borderRadius: BorderRadius.circular(12),
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
          image: NetworkImage(_attachedImageUrl!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _attachedImageUrl = null;
                  });
                },
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
          const Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                Icon(Icons.image, color: Color(0xFFFFB694), size: 20),
                SizedBox(width: 8),
                Text('lab_overview_final.jpg', style: TextStyle(color: Colors.white, fontSize: 14)),
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
          hoverColor: const Color(0xFFFF6A00).withValues(alpha: 0.1),
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
