import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../shared/widgets/main_bottom_nav.dart';
import '../../shared/widgets/stats_card.dart';
import '../auth/presentation/providers/auth_providers.dart';

// ==========================================
// GLOBAL CONSTANTS AND CONFIGURATION
// ==========================================

const _avatarsBucket = 'avatars';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _error;

  String _displayEmail = '';
  String? _avatarUrl;
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Map<String, dynamic>> _myPosts = const [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Session expired. Please login again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile =
          await _client.from('profiles').select().eq('id', user.id).maybeSingle();

      List<Map<String, dynamic>> postsRaw = const [];
      var postsCountValue = 0;
      var followingCountValue = 0;
      var followersCountValue = 0;

      // Optional data sources are loaded defensively so profile rendering
      // still works even if a migration/table/relation is missing.
      try {
        postsRaw = (await _client
                .from('posts')
                .select(
                    'id, content, title, created_at, club:clubs(name), post_media(media_url)')
                .eq('author_id', user.id)
                .eq('is_deleted', false)
                .order('created_at', ascending: false)
                .limit(20))
            .cast<Map<String, dynamic>>();
      } catch (_) {
        postsRaw = const [];
      }

      try {
        final postsCount = await _client
            .from('posts')
            .select('id')
            .eq('author_id', user.id)
            .eq('is_deleted', false)
            .count(CountOption.exact);
        postsCountValue = postsCount.count;
      } catch (_) {
        postsCountValue = 0;
      }

      try {
        final followingCount = await _client
            .from('user_club_follows')
            .select('club_id')
            .eq('user_id', user.id)
            .count(CountOption.exact);
        followingCountValue = followingCount.count;
      } catch (_) {
        followingCountValue = 0;
      }

      try {
        final followersQuery = await _client
            .from('reactions')
            .select('user_id, post:posts!inner(author_id)')
            .eq('post.author_id', user.id);

        final followerIds = <String>{};
        for (final row in followersQuery as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final uid = map['user_id']?.toString();
          if (uid != null && uid != user.id) {
            followerIds.add(uid);
          }
        }
        followersCountValue = followerIds.length;
      } catch (_) {
        followersCountValue = 0;
      }

      if (!mounted) return;

      _nameController.text = (profile?['full_name']?.toString() ?? '').trim();
      _bioController.text = (profile?['bio']?.toString() ?? '').trim();
      _studentIdController.text =
          (profile?['student_id']?.toString() ?? '').trim();
      _batchController.text = (profile?['batch']?.toString() ?? '').trim();
      _sectionController.text = (profile?['section']?.toString() ?? '').trim();

      setState(() {
        _displayEmail = profile?['email']?.toString() ?? user.email ?? '';
        _avatarUrl = profile?['avatar_url']?.toString();
        _postsCount = postsCountValue;
        _followingCount = followingCountValue;
        _followersCount = followersCountValue;
        _myPosts = postsRaw;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load profile data.';
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'batch': _batchController.text.trim(),
        'section': _sectionController.text.trim(),
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      await _loadProfileData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save profile.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (image == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _error = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final extension = _fileExtension(image.name);
      final objectPath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from(_avatarsBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl =
          _client.storage.from(_avatarsBucket).getPublicUrl(objectPath);

      await _client.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', user.id);

      if (!mounted) return;
      await _loadProfileData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Avatar upload failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  String _fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) return 'jpg';
    final ext = fileName.substring(dot + 1).toLowerCase();
    if (ext == 'png' || ext == 'webp' || ext == 'jpg' || ext == 'jpeg') {
      return ext == 'jpeg' ? 'jpg' : ext;
    }
    return 'jpg';
  }

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    ref.invalidate(authNotifierProvider);
    ref.invalidate(authSessionProvider);

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isSaving || _isUploadingAvatar;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.25)),
                            ),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        _buildHeaderCard(isBusy),
                        const SizedBox(height: 12),
                        _buildStatsGrid(),
                        const SizedBox(height: 12),
                        _buildProfileForm(isBusy),
                        const SizedBox(height: 12),
                        _buildMyPosts(),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: isBusy ? null : _logout,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar:
          const MainBottomNav(activeRoute: AppRoutes.profileDashboard),
    );
  }

  Widget _buildHeaderCard(bool isBusy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.cta.withValues(alpha: 0.2),
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? Text(
                        _initial(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: InkWell(
                  onTap: isBusy ? null : _uploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isUploadingAvatar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Your Name'
                      : _nameController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  _bioController.text.trim().isEmpty
                      ? 'Add a short bio to tell others about your interests.'
                      : _bioController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: columns == 1 ? 2.2 : 2.4,
          children: [
            StatsCard(
              label: 'Posts',
              value: _postsCount.toString(),
              icon: Icons.post_add_outlined,
            ),
            StatsCard(
              label: 'Followers',
              value: _followersCount.toString(),
              icon: Icons.people_outline,
            ),
            StatsCard(
              label: 'Following',
              value: _followingCount.toString(),
              icon: Icons.group_add_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileForm(bool isBusy) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Profile Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(labelText: 'Student ID'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _batchController,
                  decoration: const InputDecoration(labelText: 'Batch'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _sectionController,
                  decoration: const InputDecoration(labelText: 'Section'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isBusy ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPosts() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'My Posts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (_myPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'You have not published any posts yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myPosts.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final row = _myPosts[index];
                final club = row['club'] as Map<String, dynamic>?;
                final media = (row['post_media'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    const [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['title']?.toString().trim().isNotEmpty == true
                          ? row['title'].toString()
                          : (club?['name']?.toString() ?? 'Club Post'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row['content']?.toString() ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          media.first['media_url']?.toString() ?? '',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => Container(
                            height: 80,
                            color: AppColors.surfaceSoft,
                            alignment: Alignment.center,
                            child: const Text('Image unavailable'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatTimestamp(row['created_at']?.toString()),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _initial() {
    final value = _nameController.text.trim();
    if (value.isEmpty) return 'U';
    return value.characters.first.toUpperCase();
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return 'just now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'just now';

    final local = parsed.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
