import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/dropdown_field.dart';
import '../../../../../shared/widgets/input_field.dart';
import '../../../../../shared/widgets/primary_button.dart';

Future<void> showProfileEditModal(
  BuildContext context, {
  required String name,
  required String studentId,
  required String batch,
  required String section,
  required String department,
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
  });

  final String name;
  final String studentId;
  final String batch;
  final String section;
  final String department;

  @override
  State<_ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<_ProfileEditModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _batchController;
  late final TextEditingController _sectionController;
  late String _department;
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
                    'This is a UI-first modal. Wire the save action to the existing profile update flow when needed.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
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
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile edit UI is ready. Hook it to the existing update flow when required.'),
                        ),
                      );
                    },
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
