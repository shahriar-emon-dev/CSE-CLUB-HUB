import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_config.dart';
import '../../../models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/role_based_drawer.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../../events/providers/events_provider.dart';
import '../../../models/club.dart';
import '../../../models/event.dart';
final profileProvider = FutureProvider.family<UserProfile?, String?>((ref, userId) async {
  final id = userId ?? SupabaseConfig.currentUserId;
  if (id == null) return null;
  final data = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return UserProfile.fromJson(data);
});

/// User Profile and Dashboard Screen.
/// 
/// Displays the user's avatar, standard details, and role. For the current user,
/// this screen provides access to editing profile details (via secure RPC),
/// and displays their saved posts, events, and managed clubs (if Executive).
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  
  // Controllers for Edit Mode
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _studentIdCtrl;
  late TextEditingController _batchCtrl;
  late TextEditingController _semesterCtrl;
  late TextEditingController _groupCtrl;
  String _selectedDept = 'Computer Science';
  List<String> _interests = ['UI Design', 'Robotics', 'Generative Art'];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _studentIdCtrl = TextEditingController();
    _batchCtrl = TextEditingController();
    _semesterCtrl = TextEditingController();
    _groupCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _studentIdCtrl.dispose();
    _batchCtrl.dispose();
    _semesterCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  void _showAddInterestDialog() {
    final TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        title: const Text('Add Interest', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Machine Learning',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true, fillColor: const Color(0xFF0D0D14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_interests.contains(value.trim())) {
              setState(() => _interests.add(value.trim()));
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty && !_interests.contains(ctrl.text.trim())) {
                setState(() => _interests.add(ctrl.text.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode(UserProfile? profile) {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && profile != null) {
        _nameCtrl.text = profile.fullName;
        _studentIdCtrl.text = profile.studentId ?? '';
        _batchCtrl.text = profile.batch ?? '';
        _semesterCtrl.text = profile.semester ?? '';
        _groupCtrl.text = profile.group ?? '';
        _selectedDept = profile.department ?? 'Computer Science';
        _bioCtrl.text = profile.bio ?? 'Creative Technologist exploring the intersection of AI and spatial design. Late night studio dweller.';
        _interests = profile.skills.isNotEmpty ? List.from(profile.skills) : ['UI Design', 'Robotics', 'Generative Art'];
      }
    });
  }

  Future<void> _saveChanges(UserProfile profile) async {
    try {
      await SupabaseConfig.client.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'student_id': _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
        'department': _selectedDept,
        'batch': _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
        'semester': _semesterCtrl.text.trim().isEmpty ? null : _semesterCtrl.text.trim(),
        'group': _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': _interests,
      }).eq('id', profile.id);
      
      ref.invalidate(profileProvider(widget.userId));
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.code == '23505' && e.message.contains('profiles_student_id_key')) {
          errorMessage = 'This Student ID is already registered to another account.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $errorMessage', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(UserProfile profile) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      
      setState(() => _isUploading = true);
      
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${profile.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;
      
      await SupabaseConfig.client.storage.from('avatars').uploadBinary(
        filePath, 
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );
      
      final publicUrl = SupabaseConfig.client.storage.from('avatars').getPublicUrl(filePath);
      
      await SupabaseConfig.client.from('profiles').update({'avatar_url': publicUrl}).eq('id', profile.id);
      
      ref.invalidate(profileProvider(widget.userId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  bool get _isOwnProfile => widget.userId == null || widget.userId == SupabaseConfig.currentUserId;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.userId));
    
    final followedClubsIds = ref.watch(followedClubsProvider).valueOrNull ?? [];
    final allClubs = ref.watch(clubsProvider).valueOrNull ?? [];
    final followedClubs = allClubs.where((c) => followedClubsIds.contains(c.id)).toList();

    final rsvpsMap = ref.watch(myAllRsvpsProvider).valueOrNull ?? {};
    final allEvents = ref.watch(eventsProvider).valueOrNull ?? [];
    final myRsvps = allEvents.where((e) => rsvpsMap[e.id] == RsvpStatus.confirmed).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14).withValues(alpha: 0.8),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('ClubHub', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondaryDark),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withValues(alpha: 0.05), height: 1),
        ),
      ),
      drawer: const RoleBasedDrawer(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            child: _isEditing ? _buildEditMode(profile) : _buildViewMode(profile, followedClubs, myRsvps),
          );
        },
      ),
    );
  }

  Widget _buildViewMode(UserProfile profile, List<Club> followedClubs, List<Event> myRsvps) {
    return SingleChildScrollView(
      key: const ValueKey('view_mode'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Profile
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: -10),
                  ],
                ),
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                    color: AppColors.surfaceContainerDark,
                  ),
                  child: ClipOval(
                    child: profile.avatarUrl != null
                        ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 60, color: AppColors.textSecondaryDark),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(profile.fullName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text('Student · ${profile.department ?? 'N/A'} · Batch ${profile.batch ?? 'N/A'}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
              ),
              const SizedBox(height: 24),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(followedClubs.length.toString(), 'CLUBS'),
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 32)),
                  _buildStatItem(myRsvps.length.toString(), 'EVENTS'),
                ],
              ),
              const SizedBox(height: 32),
              
              // Actions
              if (_isOwnProfile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _toggleEditMode(profile),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {},
                        child: const Icon(Icons.settings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                        child: const Icon(Icons.logout),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Followed Clubs Horizontal Scroll
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Followed Clubs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              InkWell(
                onTap: () {},
                child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: followedClubs.isEmpty
                ? const Text('No followed clubs.', style: TextStyle(color: AppColors.textSecondaryDark))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: followedClubs.map((c) {
                      Color color = AppColors.primary;
                      if (c.colorHex != null) {
                        try {
                          color = Color(int.parse('FF${c.colorHex!.replaceAll('#', '')}', radix: 16));
                        } catch (_) {}
                      }
                      return _buildClubChip(c.name, color);
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 32),
          
          // Recent Activity Bento
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final upcoming = myRsvps.where((e) => e.eventDate.isAfter(now)).toList()
                      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
                    
                    if (upcoming.isNotEmpty) {
                      final nextEvent = upcoming.first;
                      return _buildBentoCard(
                        label: 'NEXT EVENT',
                        labelColor: AppColors.primary,
                        title: nextEvent.title,
                        subtitle: '${nextEvent.eventDate.toString().substring(0, 10)} · ${nextEvent.venue ?? "TBD"}',
                      );
                    } else {
                      return _buildBentoCard(
                        label: 'NEXT EVENT',
                        labelColor: AppColors.primary,
                        title: 'No Upcoming Events',
                        subtitle: 'Check the feed to RSVP!',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBentoCard(
                  label: 'ACHIEVEMENTS',
                  labelColor: AppColors.tertiaryContainer,
                  title: profile.role == UserRole.superAdmin ? 'Super Admin' : (profile.role == UserRole.executive ? 'Club Executive' : 'Active Member'),
                  subtitle: profile.role == UserRole.superAdmin ? 'System Administrator' : 'Leading the way.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEditMode(UserProfile profile) {
    return SingleChildScrollView(
      key: const ValueKey('edit_mode'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(backgroundColor: AppColors.surfaceVariantDark.withValues(alpha: 0.3)),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _toggleEditMode(null),
              ),
              const SizedBox(width: 16),
              const Text('Edit Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Avatar Upload section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF13131F).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surfaceContainerDark),
                  child: ClipOval(
                    child: profile.avatarUrl != null
                        ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt, color: Colors.white54, size: 32),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Picture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('PNG or JPG. Max 2MB.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _isUploading ? null : () => _pickAndUploadImage(profile),
                        child: Text(_isUploading ? 'Uploading...' : 'Change Photo', style: TextStyle(color: _isUploading ? AppColors.textSecondaryDark : AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildEditField('DISPLAY NAME', _nameCtrl),
          const SizedBox(height: 24),
          
          _buildEditField('STUDENT ID', _studentIdCtrl),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildEditField('BATCH', _batchCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildEditField('SEMESTER', _semesterCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildEditField('GROUP', _groupCtrl)),
            ],
          ),
          const SizedBox(height: 24),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DEPARTMENT', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedDept,
                dropdownColor: const Color(0xFF13131F),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFF0D0D14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                ),
                items: ['Computer Science', 'Digital Design', 'Fine Arts', 'Architecture'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) => setState(() => _selectedDept = v!),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildEditField('BIO', _bioCtrl, maxLines: 4),
          const SizedBox(height: 24),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INTERESTS', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  ..._interests.map((interest) => Chip(
                    label: Text(interest, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
                    onDeleted: () => setState(() => _interests.remove(interest)),
                  )),
                  ActionChip(
                    label: const Text('+ Add Interest', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3), style: BorderStyle.solid),
                    onPressed: _showAddInterestDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _toggleEditMode(null),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  onPressed: () => _saveChanges(profile),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFF0D0D14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildClubChip(String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.category, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBentoCard({required String label, required Color labelColor, required String title, required String subtitle}) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
        ],
      ),
    );
  }
}
