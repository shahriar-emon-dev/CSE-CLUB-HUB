import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/clubs_provider.dart';
import '../../../models/club.dart';

class EditClubScreen extends ConsumerStatefulWidget {
  final String clubSlug; // Or clubId, depending on route setup, let's use clubSlug to fetch
  const EditClubScreen({super.key, required this.clubSlug});

  @override
  ConsumerState<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<EditClubScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  
  Club? _initialClub;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _categoriesController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initFields(Club club) {
    if (_isInitialized) return;
    _initialClub = club;
    _nameController.text = club.name;
    _bioController.text = club.description ?? '';
    _categoriesController.text = club.categories.join(', ');
    _scheduleController.text = club.meetingSchedule ?? '';
    _locationController.text = club.location ?? '';
    _isInitialized = true;
  }

  void _saveChanges() async {
    if (_initialClub == null) return;
    
    final categories = _categoriesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await ref.read(editClubNotifierProvider.notifier).updateClubProfile(
      _initialClub!.id,
      name: _nameController.text,
      bio: _bioController.text,
      categories: categories,
      meetingSchedule: _scheduleController.text,
      location: _locationController.text,
    );

    if (!mounted) return;
    
    final state = ref.read(editClubNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${state.error}', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
      // Invalidate to refresh data
      ref.invalidate(clubDetailProvider(widget.clubSlug));
      ref.invalidate(clubsProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(clubDetailProvider(widget.clubSlug));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: clubAsync.when(
        data: (club) {
          if (club == null) {
            return const Center(child: Text('Club not found', style: TextStyle(color: Colors.white)));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _initFields(club));

          return _buildContent(club);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildContent(Club club) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Profile', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
          centerTitle: true,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              children: [
                _buildHeaderSection(club),
                const SizedBox(height: 32),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(Club club) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        Container(
          height: 192, // h-48 equivalent
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(4),
            ),
            border: const Border(left: BorderSide(color: Color(0xFFFF6A00), width: 4)),
            image: club.coverImageUrl != null
                ? DecorationImage(image: NetworkImage(club.coverImageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.bgDark, Colors.transparent],
                  ),
                ),
              ),
              // Camera Hover overlay
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      // Trigger cover image upload
                    },
                    hoverColor: AppColors.bgDark.withValues(alpha: 0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.photo_camera, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Profile Logo
        Positioned(
          bottom: -48,
          left: 32,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerDark,
              border: Border.all(color: AppColors.bgDark, width: 4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                  blurRadius: 32,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                )
              ],
              image: club.logoUrl != null
                  ? DecorationImage(image: NetworkImage(club.logoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Trigger logo image upload
                },
                hoverColor: AppColors.bgDark.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    final isLoading = ref.watch(editClubNotifierProvider).isLoading;

    return Column(
      children: [
        // Basic Info Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            border: Border.all(color: const Color(0xFFFF6A00).withValues(alpha: 0.1)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Club Information', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField('CLUB NAME', _nameController, maxLines: 1),
              const SizedBox(height: 24),
              _buildBioField(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Metadata Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            border: Border.all(color: const Color(0xFFFF6A00).withValues(alpha: 0.1)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metadata', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField('CATEGORIES (Comma Separated)', _categoriesController, maxLines: 1),
              const SizedBox(height: 16),
              _buildTextField('MEETING SCHEDULE', _scheduleController, maxLines: 1),
              const SizedBox(height: 16),
              _buildTextField('LOCATION', _locationController, maxLines: 1),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: const Color(0xFF571F00),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(4),
                ),
              ),
              elevation: 12,
              shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.3),
            ),
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF571F00), strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Last updated: Just now', style: TextStyle(color: Colors.white30, fontSize: 12)),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF170B06), // surface-container-lowest
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BIO', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF170B06),
                counterText: '', // Hide default counter to use custom one
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
                ),
              ),
              onChanged: (text) {
                setState(() {}); // trigger rebuild for counter
              },
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Text(
                '${_bioController.text.length}/500',
                style: TextStyle(
                  color: _bioController.text.length > 500 ? AppColors.error : AppColors.textSecondaryDark.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
