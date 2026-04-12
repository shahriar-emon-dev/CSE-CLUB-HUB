import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ==========================================
// CORE BUSINESS LOGIC
// ==========================================

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    required this.controller,
    required this.validator,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
