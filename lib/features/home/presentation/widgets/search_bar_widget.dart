import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

// ==========================================
// SEARCH BAR WIDGET
// ==========================================

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.controller,
    required this.hintText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 28,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
