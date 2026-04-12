import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.validator,
    this.textInputAction,
    this.prefixIcon,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
