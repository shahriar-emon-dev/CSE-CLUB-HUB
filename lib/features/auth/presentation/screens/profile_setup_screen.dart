import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/auth_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  String? _requiredField(String? value, String field) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required';
    return null;
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref.read(authNotifierProvider.notifier).completeProfile(
          fullName: _fullNameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          batch: _batchController.text.trim(),
          section: _sectionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _requiredField(v, 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Student ID',
                    controller: _studentIdController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _requiredField(v, 'Student ID'),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Batch',
                    controller: _batchController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _requiredField(v, 'Batch'),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Section',
                    controller: _sectionController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    validator: (v) => _requiredField(v, 'Section'),
                  ),
                  const SizedBox(height: 24),
                  if (authState.errorMessage != null)
                    Text(
                      authState.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  if (authState.errorMessage != null) const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Save Profile',
                    isLoading: authState.isLoading,
                    onPressed: _saveProfile,
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
