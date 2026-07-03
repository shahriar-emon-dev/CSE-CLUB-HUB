import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/events_provider.dart';
import '../widgets/cancel_event_dialog.dart';
import '../../../models/event.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _venueController;
  late TextEditingController _capacityController;
  
  String _category = 'general';
  bool _registrationRequired = true;
  String? _coverImageUrl;
  bool _initialized = false;
  
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
    _venueController = TextEditingController();
    _capacityController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _initializeFields(Event event) {
    if (_initialized) return;
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _category = event.category.value;
    
    // Formatting dates and times
    _dateController.text = event.eventDate.toIso8601String().split('T')[0];
    _startTimeController.text = "${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}";
    if (event.endDate != null) {
      _endTimeController.text = "${event.endDate!.hour.toString().padLeft(2, '0')}:${event.endDate!.minute.toString().padLeft(2, '0')}";
    }
    
    _venueController.text = event.venue ?? '';
    _capacityController.text = event.capacity?.toString() ?? '';
    _coverImageUrl = event.coverImageUrl;
    
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final notifierState = ref.watch(eventNotifierProvider);
    final isUpdating = notifierState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: SafeArea(
            bottom: false,
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
                    Text('Edit Event', style: GoogleFonts.sora(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.notifications, color: AppColors.textSecondaryDark), onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (event) {
          if (event == null) return const Center(child: Text('Event not found.', style: TextStyle(color: Colors.white)));
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeFields(event);
            if (mounted) setState(() {}); // To reflect initial values in UI
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildMainInfoCard(),
                  const SizedBox(height: 24),
                  _buildLogisticsGrid(),
                  const SizedBox(height: 24),
                  _buildSettingsCard(),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, isUpdating, event),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Details', style: GoogleFonts.sora(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildCoverImageUpload(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Event Title', _titleController)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('Category', style: GoogleFonts.firaSans(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: EventCategory.values.any((c) => c.value == _category) ? _category : 'general',
                      dropdownColor: AppColors.surfaceContainerDark,
                      style: GoogleFonts.firaSans(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
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
                      items: EventCategory.values
                          .map((e) => DropdownMenuItem(value: e.value, child: Text(e.displayName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField('Description', _descriptionController, maxLines: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageUpload() {
    ImageProvider imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else if (_coverImageUrl != null) {
      imageProvider = NetworkImage(_coverImageUrl!);
    } else {
      imageProvider = const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBYDcGHYZ6kz7So-WexpV5nrJA6C26BttBD1fgj_4fUk1gMy2WZFQB02I8Tk7uDTEZbKglHz-_xIkmVgsmwf5ST5_mBqorpBdhEsJI8hzP18DudP5DUnCSL0Xcivrj-xViVmWnPL88dzEsQSBq0dd75F74fAW2m6WdoI2EkEfm3AFc4kmdPOLF-1GzS4beiVaMdI4l9OkqIsIKDK4Xv5mnw8_MvSZjQoFptdOLlAe-xQTaV4PfBrGhe3TfFccIHhBtncILLtvQsuqk');
    }
        
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                Text('Change Cover Image', style: GoogleFonts.firaSans(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildLogisticsGrid() {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    
    Widget content = isDesktop ? Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildScheduleCard()),
        const SizedBox(width: 24),
        Expanded(child: _buildVenueCard()),
      ],
    ) : Column(
      children: [
        _buildScheduleCard(),
        const SizedBox(height: 24),
        _buildVenueCard(),
      ],
    );
    
    return content;
  }
  
  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Schedule', style: GoogleFonts.sora(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Date', _dateController, labelSize: 12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Start Time', _startTimeController, labelSize: 12)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('End Time', _endTimeController, labelSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVenueCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Venue', style: GoogleFonts.sora(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Location Name', _venueController, labelSize: 12),
          const SizedBox(height: 16),
          Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCZNP8gslA3MkguY2cq8l7grhfxGwdAspw3cYYFQ7u7z4WJaRMWez1Is_ZF_Ve8sQi5FrsV-H0ZxhQiMND0yKIkqJRqILOyadORhxorVPOoFw0C1A93TZnzhahYprpJDqpRj_qujYnyOugrXYFZ3pjIv7T4qm31Ug2eY5Q7hL_1wtJgkz-0ilIYWjbelEAD3Mb3ao3vbMH6xWo-Pip17OF38tnEljRyrrG3R9EV53yheqSJHQzXLn3FK5tyFlTTwQz5Bjc4HMIqPEE'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Advanced Settings', style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registration Required', style: GoogleFonts.firaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Users must RSVP to attend this event.', style: GoogleFonts.firaSans(color: AppColors.textSecondaryDark, fontSize: 14)),
                  ],
                ),
              ),
              Switch(
                value: _registrationRequired,
                onChanged: (val) => setState(() => _registrationRequired = val),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.textSecondaryDark,
                inactiveTrackColor: AppColors.surfaceVariantDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacity Limit', style: GoogleFonts.firaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Maximum attendees permitted.', style: GoogleFonts.firaSans(color: AppColors.textSecondaryDark, fontSize: 14)),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaSans(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isUpdating, Event event) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isUpdating ? null : () => _handleUpdateEvent(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF571F00),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: isUpdating
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF571F00)),
                  )
                : Text(
                    'Update Event',
                    style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: OutlinedButton.icon(
            onPressed: isUpdating ? null : () async {
              final result = await showDialog<bool>(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.7),
                builder: (context) => CancelEventDialog(
                  eventId: event.id,
                  rsvpCount: event.rsvpCount ?? 0,
                ),
              );
              if (result == true) {
                if (!context.mounted) return;
                context.pop(); // Go back if event was successfully cancelled
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: Text('Cancel Event', style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.error.withValues(alpha: 0.2),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, double labelSize = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.firaSans(color: AppColors.textSecondaryDark, fontSize: labelSize, fontWeight: FontWeight.w500)),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.firaSans(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
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
  
  Future<void> _handleUpdateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      // Parse date and time
      final dateStr = _dateController.text.trim();
      final startStr = _startTimeController.text.trim();
      final endStr = _endTimeController.text.trim();
      
      final startDate = DateTime.parse('${dateStr}T$startStr:00');
      DateTime? endDate;
      if (endStr.isNotEmpty) {
        endDate = DateTime.parse('${dateStr}T$endStr:00');
      }

      if (_imageBytes != null || _selectedImage != null) {
        final uploadedUrl = await _uploadImage(widget.eventId);
        if (uploadedUrl != null) {
          _coverImageUrl = uploadedUrl;
        }
      }

      await ref.read(eventNotifierProvider.notifier).updateEvent(
        widget.eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        venue: _venueController.text.trim(),
        eventDate: startDate,
        endDate: endDate,
        capacity: int.tryParse(_capacityController.text.trim()),
        coverImageUrl: _coverImageUrl,
      );
      
      if (mounted) {
        // Refresh details
        ref.invalidate(eventDetailProvider(widget.eventId));
        ref.invalidate(eventsProvider);
        final currentEvent = ref.read(eventDetailProvider(widget.eventId)).value;
        if (currentEvent?.organizingClubId != null) {
          ref.invalidate(clubEventsProvider(currentEvent!.organizingClubId!));
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event Updated Successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }
}
