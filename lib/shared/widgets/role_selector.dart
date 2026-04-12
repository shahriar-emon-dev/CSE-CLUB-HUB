import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.requestExecutiveAccess,
    required this.onChanged,
    super.key,
  });

  final bool requestExecutiveAccess;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<bool>(
          groupValue: requestExecutiveAccess,
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
          child: Column(
            children: const [
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: Text('Student'),
                value: false,
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                title: Text('Request Executive Access'),
                value: true,
              ),
            ],
          ),
        ),
        const Text(
          'Executive access requires admin approval',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
