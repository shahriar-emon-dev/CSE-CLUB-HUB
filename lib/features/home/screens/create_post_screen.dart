
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../clubs/providers/club_posts_provider.dart';
import '../providers/home_feed_provider.dart';

/// Screen allowing Executives and Admins to broadcast new posts to the community.
/// 
/// This interface handles text composition, image picking (with cross-platform 
/// support for Web and Mobile), and uploading to the designated club. It also 
/// enforces role-based access, ensuring regular students cannot access it.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isPinned = false;
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _selectedClubId;

  @override
  void initState() {
    super.initState();
    _fetchExecutiveClubIfMissing();
  }

  Future<void> _fetchExecutiveClubIfMissing() async {
    final user = await ref.read(currentProfileProvider.future);
    if (user != null && user.isExecutive && user.managedClubId == null) {
      try {
        final res = await SupabaseConfig.client
            .from('club_executives')
            .select('club_id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (res != null && mounted) {
          setState(() {
            _selectedClubId = res['club_id'] as String;
          });
        }
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageFile = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _submitPost(String finalClubId) async {
    if (_textController.text.trim().isEmpty) return;
    
    await ref.read(createClubPostNotifierProvider.notifier).createPost(
      clubId: finalClubId,
      content: _textController.text.trim(),
      imageBytes: _selectedImageBytes,
      imageExtension: _selectedImageFile?.name.split('.').last ?? 'jpg',
      isPinned: _isPinned,
    );
    
    final postState = ref.read(createClubPostNotifierProvider);
    
    if (postState.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Error: ${postState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    ref.invalidate(homeFeedProvider);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentProfileProvider);
    final isCreating = ref.watch(createClubPostNotifierProvider).isLoading;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null || (!user.isSuperAdmin && !user.isExecutive)) {
            return const Center(child: Text("Unauthorized", style: TextStyle(color: Colors.white)));
          }

          if (user.isExecutive && _selectedClubId == null && user.managedClubId != null) {
            _selectedClubId = user.managedClubId;
          }

          return Stack(
            children: [
              Positioned(
                bottom: -100, right: -100,
                child: Container(
                  width: 400, height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: _buildComposerCard(user, isCreating),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isCreating)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
            ],
          );
        }
      )
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text('New Broadcast', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: const [
                Icon(Icons.stars, color: AppColors.tertiary, size: 16),
                SizedBox(width: 6),
                Text('Executive Dashboard', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard(dynamic user, bool isCreating) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1311),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _buildExecutiveAccentHeader(user),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  enabled: !isCreating,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: "What's happening in the lab?",
                    hintStyle: TextStyle(color: AppColors.textSecondaryDark),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                if (_selectedImageBytes != null)
                  _buildImagePreview()
                else
                  _buildEmptyMediaPicker(isCreating),

                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 24),
                
                _buildControlsRow(isCreating),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveAccentHeader(dynamic user) {
    final clubsAsync = ref.watch(clubsProvider);
    final selectedClub = clubsAsync.value?.where((c) => c.id == _selectedClubId).firstOrNull;
    final clubName = selectedClub?.name ?? 'Club Broadcast';

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(4),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF261812), // surface-container-high/50
          border: Border(
            bottom: BorderSide(color: Color(0x1AFFFFFF)),
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: user.isSuperAdmin 
            ? _buildSuperAdminClubSelector()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.precision_manufacturing, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clubName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('Posting as Executive Admin', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuperAdminClubSelector() {
    final clubsAsync = ref.watch(clubsProvider);
    return clubsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const SizedBox(),
      data: (clubs) {
        if (_selectedClubId == null && clubs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedClubId = clubs.first.id;
            });
          });
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Target Club', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClubId,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceContainerHighDark,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedClubId = newValue;
                    });
                  },
                  items: clubs.map<DropdownMenuItem<String>>((club) {
                    return DropdownMenuItem<String>(
                      value: club.id,
                      child: Text(club.name),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyMediaPicker(bool isCreating) {
    return GestureDetector(
      onTap: isCreating ? null : _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image, color: AppColors.textSecondaryDark, size: 32),
              SizedBox(height: 8),
              Text('Add Media', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              kIsWeb 
                ? Image.network(_selectedImageFile!.path, fit: BoxFit.cover)
                : Image.file(File(_selectedImageFile!.path), fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedImageFile = null;
                    _selectedImageBytes = null;
                  }),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(_selectedImageFile?.name ?? 'image.jpg', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow(bool isCreating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: isCreating ? null : _pickImage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isCreating ? null : () => setState(() => _isPinned = !_isPinned),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isPinned ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isPinned ? AppColors.primary : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: _isPinned ? AppColors.primary : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isPinned ? 'Pinned' : 'Pin Post',
                      style: TextStyle(
                        color: _isPinned ? AppColors.primary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        ElevatedButton(
          onPressed: (_textController.text.isNotEmpty && _selectedClubId != null && !isCreating) 
              ? () => _submitPost(_selectedClubId!) 
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Row(
            children: [
              Text(
                isCreating ? 'Posting...' : 'Post',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!isCreating) ...const [
                SizedBox(width: 8),
                Icon(Icons.send_rounded, size: 18),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
