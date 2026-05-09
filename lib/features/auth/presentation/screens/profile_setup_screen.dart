import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/dropdown_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/profile_avatar_picker.dart';
import '../providers/auth_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _batchController = TextEditingController();
  final _sectionController = TextEditingController();
  final List<String> _departments = const ['CSE', 'EEE', 'BBA', 'English', 'Law'];

  String? _department;
  String? _avatarSelectionLabel;
  bool _isFormComplete = false;

  @override
  void initState() {
    super.initState();

    _fullNameController.addListener(_refreshCompletion);
    _studentIdController.addListener(_refreshCompletion);
    _batchController.addListener(_refreshCompletion);
    _sectionController.addListener(_refreshCompletion);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_refreshCompletion);
    _studentIdController.removeListener(_refreshCompletion);
    _batchController.removeListener(_refreshCompletion);
    _sectionController.removeListener(_refreshCompletion);

    _fullNameController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  // Purpose: Keep CTA state in sync with required form fields for a better first-time setup UX.
  void _refreshCompletion() {
    final completed = _fullNameController.text.trim().isNotEmpty &&
        _studentIdController.text.trim().isNotEmpty &&
        _batchController.text.trim().isNotEmpty &&
        _sectionController.text.trim().isNotEmpty &&
        (_department?.trim().isNotEmpty ?? false);

    if (completed == _isFormComplete) return;
    setState(() => _isFormComplete = completed);
  }

  String? _requiredField(String? value, String field) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required';
    return null;
  }

  // Purpose: Keeps avatar upload UI ready for storage integration without changing existing profile logic.
  void _onAvatarSelectPressed() {
    setState(() {
      _avatarSelectionLabel = 'avatar_placeholder.png';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar upload UI is ready. Connect storage upload in Week 2 backend wiring.'),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref.read(authNotifierProvider.notifier).completeProfile(
          fullName: _fullNameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          batch: _batchController.text.trim(),
          section: _sectionController.text.trim(),
          department: _department!.trim(),
        );
  }

  String? _requiredDepartment(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Department is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Step 2/2',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your details to continue',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProfileAvatarPicker(
                          onTap: _onAvatarSelectPressed,
                          selectionLabel: _avatarSelectionLabel,
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Full Name',
                          hintText: 'Enter your full name',
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          validator: (v) => _requiredField(v, 'Full name'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Student ID',
                          hintText: 'e.g. 221-15-5234',
                          controller: _studentIdController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: (v) => _requiredField(v, 'Student ID'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Batch',
                          hintText: 'e.g. 54',
                          controller: _batchController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: (v) => _requiredField(v, 'Batch'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Section',
                          hintText: 'e.g. A',
                          controller: _sectionController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          validator: (v) => _requiredField(v, 'Section'),
                        ),
                        const SizedBox(height: 16),
                        DropdownField(
                          label: 'Department',
                          value: _department,
                          items: _departments,
                          validator: _requiredDepartment,
                          onChanged: (value) {
                            setState(() => _department = value);
                            _refreshCompletion();
                          },
                        ),
                        const SizedBox(height: 24),
                        if (authState.errorMessage != null)
                          Text(
                            authState.errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        if (authState.errorMessage != null) const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Complete Setup',
                          isLoading: authState.isLoading,
                          onPressed: _isFormComplete ? _saveProfile : null,
                        ),
                        SizedBox(height: constraints.maxHeight > 700 ? 12 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          ),
        ),
    );
  }
}
