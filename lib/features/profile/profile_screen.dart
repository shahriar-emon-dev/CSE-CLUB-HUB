import 'dart:math' as math;

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

const _avatarsBucket = 'avatars';

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
  String _department = 'CSE';
  String? _avatarUrl;
  String _joinedLabel = 'Joined recently';
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

  Future<Map<String, dynamic>?> _fetchProfileRow(String userId) async {
    try {
      final data = await _client.rpc('get_my_profile');
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  Future<int> _safeCount(
    String table,
    String column,
    String value,
  ) async {
    try {
      final response = await _client
          .from(table)
          .select('id')
          .eq(column, value)
          .count(CountOption.exact);
      return response.count;
    } catch (_) {
      return 0;
    }
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

    final profile = await _fetchProfileRow(user.id);

    List<Map<String, dynamic>> postsRaw = const [];
    try {
      postsRaw = (await _client
              .from('posts')
              .select('id, title, content, created_at, post_media(media_url)')
              .eq('author_id', user.id)
              .eq('is_deleted', false)
              .order('created_at', ascending: false)
              .limit(30))
          .cast<Map<String, dynamic>>();
    } catch (_) {
      postsRaw = const [];
    }

    final postsCountValue = await _safeCount('posts', 'author_id', user.id);

    var followersCountValue = await _safeCount('follows', 'followed_id', user.id);
    var followingCountValue = await _safeCount('follows', 'follower_id', user.id);

    if (followingCountValue == 0) {
      followingCountValue = await _safeCount('user_club_follows', 'user_id', user.id);
    }

    if (!mounted) return;

    _nameController.text = (profile?['full_name']?.toString() ?? '').trim();
    _bioController.text = (profile?['bio']?.toString() ?? '').trim();
    _studentIdController.text = (profile?['student_id']?.toString() ?? '').trim();
    _batchController.text = (profile?['batch']?.toString() ?? '').trim();
    _sectionController.text = (profile?['section']?.toString() ?? '').trim();
    _department = (profile?['department']?.toString().trim().isNotEmpty ?? false)
      ? profile!['department'].toString().trim()
      : 'CSE';

    final createdAtRaw = profile?['created_at']?.toString();
    final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);

    setState(() {
      _displayEmail =
          (profile?['email']?.toString().trim().isNotEmpty ?? false)
              ? profile!['email'].toString().trim()
              : (user.email ?? 'No email found');
      _avatarUrl = profile?['avatar_url']?.toString();
      _joinedLabel = createdAt == null
          ? 'Joined recently'
          : 'Joined ${createdAt.toLocal().year}-${createdAt.toLocal().month.toString().padLeft(2, '0')}-${createdAt.toLocal().day.toString().padLeft(2, '0')}';
      _postsCount = postsCountValue;
      _followersCount = followersCountValue;
      _followingCount = followingCountValue;
      _myPosts = postsRaw;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final savedProfile = await _saveProfileRow(avatarUrl: null);

      if (!mounted) return;
      if (savedProfile != null) {
        _applyProfileData(savedProfile, user.email);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _mapProfileSaveError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<ImageSource?> _pickImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update profile picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final source = await _pickImageSource();
    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() {
      _isUploadingAvatar = true;
      _error = null;
    });

    try {
      final bytes = await image.readAsBytes();
      final objectPath = '${user.id}/avatar.jpg';

      await _client.storage.from(_avatarsBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = _client.storage.from(_avatarsBucket).getPublicUrl(objectPath);

      final savedProfile = await _saveProfileRow(avatarUrl: publicUrl);

      if (!mounted) return;
      setState(() {
        _avatarUrl = savedProfile?['avatar_url']?.toString() ?? publicUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Avatar upload failed. Check file size and network.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _saveProfileRow({String? avatarUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const PostgrestException(message: 'No active session found. Please login again.');
    }

    final data = await _client.rpc(
      'save_my_profile',
      params: {
        'full_name': _nameController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'batch': _batchController.text.trim(),
        'section': _sectionController.text.trim(),
        'department': _department,
        'bio': _bioController.text.trim(),
        'avatar_url': avatarUrl,
      },
    );

    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  void _applyProfileData(Map<String, dynamic> profile, String? fallbackEmail) {
    _nameController.text = (profile['full_name']?.toString() ?? '').trim();
    _bioController.text = (profile['bio']?.toString() ?? '').trim();
    _studentIdController.text = (profile['student_id']?.toString() ?? '').trim();
    _batchController.text = (profile['batch']?.toString() ?? '').trim();
    _sectionController.text = (profile['section']?.toString() ?? '').trim();
    _department = (profile['department']?.toString().trim().isNotEmpty ?? false)
      ? profile['department'].toString().trim()
      : 'CSE';
    _displayEmail = (profile['email']?.toString().trim().isNotEmpty ?? false)
      ? profile['email'].toString().trim()
      : (fallbackEmail ?? 'No email found');
    _avatarUrl = profile['avatar_url']?.toString();

    final createdAtRaw = profile['created_at']?.toString();
    final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
    _joinedLabel = createdAt == null
        ? 'Joined recently'
        : 'Joined ${createdAt.toLocal().year}-${createdAt.toLocal().month.toString().padLeft(2, '0')}-${createdAt.toLocal().day.toString().padLeft(2, '0')}';
  }

  String _mapProfileSaveError(Object e) {
    if (e is PostgrestException) {
      if (e.code == '42501') {
        return 'Failed to save profile due to database permission policy. Apply latest migration and try again.';
      }
      if (e.code == '23505') {
        return 'This email is already used by another profile.';
      }
      if (e.message.isNotEmpty) {
        return 'Failed to save profile: ${e.message}';
      }
    }
    return 'Failed to save profile.';
  }

  Future<void> _showEditProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bioController,
                  minLines: 3,
                  maxLines: 5,
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
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _saveProfile();
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
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
            ? const _ProfileLoadingSkeleton()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = math.min(constraints.maxWidth, 980.0);
                  final horizontalPadding = constraints.maxWidth >= 900 ? 24.0 : 16.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            _buildHeaderCard(isBusy),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildActionButtons(isBusy),
                            const SizedBox(height: 16),
                            _buildPostsFeed(),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: isBusy ? null : _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text(
                                'Logout',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: const MainBottomNav(activeRoute: AppRoutes.profileDashboard),
    );
  }

  Widget _buildHeaderCard(bool isBusy) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientMiddle,
                  AppColors.gradientEnd,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.cta.withValues(alpha: 0.18),
                          backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                              ? Text(
                                  _initial(),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Material(
                          color: AppColors.cta,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isBusy ? null : _uploadAvatar,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.trim().isEmpty
                                ? 'Your Name'
                                : _nameController.text.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayEmail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _joinedLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              _bioController.text.trim().isEmpty
                  ? 'Add a short bio to tell others about your interests and club activities.'
                  : _bioController.text.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              label: 'Posts',
              value: _postsCount.toString(),
              icon: Icons.post_add_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatsCard(
              label: 'Followers',
              value: _followersCount.toString(),
              icon: Icons.people_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatsCard(
              label: 'Following',
              value: _followingCount.toString(),
              icon: Icons.person_add_alt_1_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isBusy) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 560;

        final editButton = FilledButton.icon(
          onPressed: isBusy ? null : _showEditProfileSheet,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cta,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        final photoButton = OutlinedButton.icon(
          onPressed: isBusy ? null : _uploadAvatar,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.inputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: _isUploadingAvatar
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: const Text(
            'Change Photo',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        if (vertical) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: editButton),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: photoButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: editButton),
            const SizedBox(width: 10),
            Expanded(child: photoButton),
          ],
        );
      },
    );
  }

  Widget _buildPostsFeed() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_myPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No posts yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                final post = _myPosts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _myPosts.length - 1 ? 0 : 14),
                  child: _buildPostCard(post),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final media = (post['post_media'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final imageUrl = media.isNotEmpty ? media.first['media_url']?.toString() : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.cta.withValues(alpha: 0.16),
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? Text(
                        _initial(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty ? 'You' : _nameController.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTimestamp(post['created_at']?.toString()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((post['title']?.toString().trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                post['title'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Text(
            post['content']?.toString() ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 110,
                  color: AppColors.surfaceSoft,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image unavailable',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _PostAction(icon: Icons.thumb_up_alt_outlined, label: 'Like'),
              _PostAction(icon: Icons.chat_bubble_outline, label: 'Comment'),
              _PostAction(icon: Icons.share_outlined, label: 'Share'),
            ],
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
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return 'just now';

    final now = DateTime.now();
    final diff = now.difference(parsed);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoadingSkeleton extends StatelessWidget {
  const _ProfileLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _SkeletonBox(height: 220, radius: 20),
          SizedBox(height: 16),
          _SkeletonBox(height: 120, radius: 20),
          SizedBox(height: 16),
          _SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 10),
          _SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 16),
          _SkeletonBox(height: 260, radius: 20),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
