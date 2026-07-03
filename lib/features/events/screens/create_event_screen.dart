import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/clubs_provider.dart';
import '../providers/events_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  int _accessTier = 0; // 0 = Public, 1 = Internal
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedClubId;
  
  // Image Upload State
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  // Text Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    }
  }

  Future<String?> _uploadImage(String eventId) async {
    if (_imageBytes == null || _selectedImage == null) return null;
    
    try {
      final extension = _selectedImage!.name.split('.').last;
      final filePath = '$eventId/cover_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      await Supabase.instance.client.storage.from('posts').uploadBinary(
        filePath,
        _imageBytes!,
        fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
      );
      
      return Supabase.instance.client.storage.from('posts').getPublicUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Stack(
        children: [
          // Ambient background light using soft radial gradients to fix shader compilation crash
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: -20,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.04),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      _buildExecutiveShell(),
                      const SizedBox(height: 100), // Bottom nav padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text('Create Event', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.hub, color: AppColors.textSecondaryDark), onPressed: () {}),
              IconButton(icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveShell() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerDark.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(2),
          bottomLeft: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24, top: 0, bottom: 0,
            child: Container(width: 4, color: AppColors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPosterUpload(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosterUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _imageBytes != null ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.5),
            ),
            color: _imageBytes != null ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
            image: _imageBytes != null
                ? DecorationImage(
                    image: MemoryImage(_imageBytes!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _imageBytes != null
              ? Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Change Poster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.8)),
                      const SizedBox(height: 12),
                      const Text('Tap to upload event poster', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('16:9 ratio recommended', style: TextStyle(color: AppColors.primary.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Event Title', controller: _titleController, hint: 'e.g. Hackathon 2024', maxLines: 1),
        const SizedBox(height: 24),
        _buildTextField('Description', controller: _descriptionController, hint: 'Provide details about your event...', maxLines: 5, expands: false),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildPickerField(
                label: 'Date',
                value: _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'Select Date',
                icon: Icons.calendar_month,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerField(
                label: 'Time',
                value: _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                icon: Icons.schedule,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildVenueField(),
        const SizedBox(height: 24),
        _buildAccessTierToggle(),
        const SizedBox(height: 24),
        _buildClubSelector(),
      ],
    );
  }

  Widget _buildClubSelector() {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        
        if (profile.isSuperAdmin) {
          final clubsAsync = ref.watch(clubsProvider);
          return clubsAsync.when(
            data: (clubs) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Organizing Club', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClubId,
                    dropdownColor: const Color(0xFF1D100A),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Select a club',
                      hintStyle: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: const Color(0xFF1D100A),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    items: clubs.map((club) {
                      return DropdownMenuItem<String>(
                        value: club.id,
                        child: Text(club.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClubId = value;
                      });
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Text('Error loading clubs: $err', style: const TextStyle(color: AppColors.error)),
          );
        } else if (profile.isExecutive) {
          // Force lock to their managed club
          _selectedClubId = profile.managedClubId;
          return const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller, String? hint, int? maxLines, bool expands = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: expands ? null : (maxLines ?? 1),
          keyboardType: maxLines != null && maxLines > 1 ? TextInputType.multiline : TextInputType.text,
          style: TextStyle(color: Colors.white, fontSize: maxLines == 1 ? 16 : 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
            filled: true,
            fillColor: const Color(0xFF1D100A),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D100A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value, 
                    style: TextStyle(
                      color: value.startsWith('Select') ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : Colors.white, 
                      fontSize: 16
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Venue', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _venueController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. Main Auditorium',
                  hintStyle: TextStyle(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: const Color(0xFF1D100A),
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.map, color: Colors.white, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessTierToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Visibility', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
        ),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _accessTier,
            backgroundColor: const Color(0xFF1D100A),
            thumbColor: AppColors.primary.withValues(alpha: 0.2),
            children: {
              0: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Public', style: TextStyle(color: _accessTier == 0 ? AppColors.primary : AppColors.textSecondaryDark, fontWeight: FontWeight.bold)),
              ),
              1: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Internal', style: TextStyle(color: _accessTier == 1 ? AppColors.primary : AppColors.textSecondaryDark, fontWeight: FontWeight.bold)),
              ),
            },
            onValueChanged: (value) {
              if (value != null) {
                setState(() => _accessTier = value);
              }
            },
          ),
        ),
      ],
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _venueController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedImage = null;
    _imageBytes = null;
    _accessTier = 0;
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: const [
                  Icon(Icons.visibility, color: AppColors.textSecondaryDark, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This event will be visible to your club members.', 
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : () async {
                if (_titleController.text.trim().isEmpty || _selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide at least a title and a date.')),
                  );
                  return;
                }

                final user = ref.read(currentProfileProvider).value;
                if (user != null && (user.isExecutive || user.isSuperAdmin) && _selectedClubId == null) {
                  final fallbackClub = ref.read(clubsProvider).value?.firstOrNull?.id;
                  setState(() {
                    _selectedClubId = user.managedClubId ?? fallbackClub;
                  });
                }

                if (_selectedClubId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an organizing club for this event.')),
                  );
                  return;
                }

                setState(() => _isUploading = true);
                
                DateTime finalDate = _selectedDate!;
                if (_selectedTime != null) {
                  finalDate = DateTime(finalDate.year, finalDate.month, finalDate.day, _selectedTime!.hour, _selectedTime!.minute);
                }

                try {
                  final eventId = await ref.read(eventNotifierProvider.notifier).submitEvent(
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    category: 'general', // Default for now
                    venue: _venueController.text.trim(),
                    eventDate: finalDate,
                    organizingClubId: _selectedClubId,
                  );

                  // Only upload image if an image is selected
                  if (_imageBytes != null || _selectedImage != null) {
                    final uploadedUrl = await _uploadImage(eventId);
                    if (uploadedUrl != null) {
                      await Supabase.instance.client
                          .from('events')
                          .update({'cover_image_url': uploadedUrl})
                          .eq('id', eventId);
                    }
                  }
                  
                  if (mounted) {
                    setState(() => _isUploading = false);
                    _resetForm();
                    
                    // Invalidate both feeds to force UI refresh across the app
                    ref.invalidate(eventsProvider);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Event published successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                        elevation: 4,
                      ),
                    );
                    
                    context.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isUploading = false);
                    final errorText = e.toString().replaceFirst('Exception: ', '').replaceFirst('PostgresException: ', '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Failed: $errorText', style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF571F00),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4, // reduced to avoid shader issues
              ),
              child: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF571F00)))
                  : const Text('Publish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

