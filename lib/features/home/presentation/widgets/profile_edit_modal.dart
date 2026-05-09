import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/dropdown_field.dart';
import '../../../../../shared/widgets/input_field.dart';
import '../../../../../shared/widgets/primary_button.dart';

const _avatarsBucket = 'avatars';

Future<void> showProfileEditModal(
  BuildContext context, {
  required String name,
  required String studentId,
  required String batch,
  required String section,
  required String department,
  String? avatarUrl,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _ProfileEditModal(
        name: name,
        studentId: studentId,
        batch: batch,
        section: section,
        department: department,
        avatarUrl: avatarUrl,
      );
    },
  );
}

class _ProfileEditModal extends StatefulWidget {
  const _ProfileEditModal({
    required this.name,
    required this.studentId,
    required this.batch,
    required this.section,
    required this.department,
    required this.avatarUrl,
  });

  final String name;
  final String studentId;
  final String batch;
  final String section;
  final String department;
  final String? avatarUrl;

  @override
  State<_ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<_ProfileEditModal> {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _batchController;
  late final TextEditingController _sectionController;
  late String _department;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  final _formKey = GlobalKey<FormState>();
  final List<String> _departments = const ['CSE', 'EEE', 'BBA', 'English', 'Law'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _studentIdController = TextEditingController(text: widget.studentId);
    _batchController = TextEditingController(text: widget.batch);
    _sectionController = TextEditingController(text: widget.section);
    _department = widget.department;
    _avatarUrl = widget.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if ((value ?? '').trim().isEmpty) return '$field is required';
    return null;
  }

  Future<void> _uploadAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;

    setState(() {
      _isUploadingAvatar = true;
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

      if (!mounted) return;
      setState(() {
        _avatarUrl = _client.storage.from(_avatarsBucket).getPublicUrl(objectPath);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture upload failed.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _client.rpc(
        'save_my_profile',
        params: {
          'full_name': _nameController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'batch': _batchController.text.trim(),
          'section': _sectionController.text.trim(),
          'department': _department,
          'avatar_url': _avatarUrl,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save profile right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update your profile details and profile picture here.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.cta.withValues(alpha: 0.16),
                          backgroundImage: _avatarUrl != null && _avatarUrl!.trim().isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null || _avatarUrl!.trim().isEmpty
                              ? Text(
                                  widget.name.isNotEmpty ? widget.name.characters.first.toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: AppColors.cta,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isUploadingAvatar ? null : _uploadAvatar,
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
                                    : const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  InputField(
                    label: 'Full Name',
                    controller: _nameController,
                    validator: (value) => _required(value, 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  InputField(
                    label: 'Student ID',
                    controller: _studentIdController,
                    validator: (value) => _required(value, 'Student ID'),
                  ),
                  const SizedBox(height: 12),
                  InputField(
                    label: 'Batch',
                    controller: _batchController,
                    validator: (value) => _required(value, 'Batch'),
                  ),
                  const SizedBox(height: 12),
                  InputField(
                    label: 'Section',
                    controller: _sectionController,
                    validator: (value) => _required(value, 'Section'),
                  ),
                  const SizedBox(height: 12),
                  DropdownField(
                    label: 'Department',
                    value: _department,
                    items: _departments,
                    validator: (value) => _required(value, 'Department'),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _department = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveProfile,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.inputBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
