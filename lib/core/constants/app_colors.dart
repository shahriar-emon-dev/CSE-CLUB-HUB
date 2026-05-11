import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light theme
  static const gradientStart = Color(0xFFFF6A00);
  static const gradientMiddle = Color(0xFFFF8C42);
  static const gradientEnd = Color(0xFFFFB347);

  static const cta = Color(0xFFFF7A00);
  static const accent = Color(0xFF1E1B4B);
  static const danger = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6B7280);
  static const background = Color(0xFFFFFFFF);
  static const inputBorder = Color(0xFFE5E7EB);
  static const surfaceSoft = Color(0xFFF5F5F5);

  // Dark theme — kept for compatibility but app forces light mode
  static const darkBackground = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFFFFFFFF);
  static const darkTextPrimary = Color(0xFF111111);
  static const darkTextSecondary = Color(0xFF6B7280);
  static const darkInputBorder = Color(0xFFE5E7EB);
  static const darkSurfaceSoft = Color(0xFFF5F5F5);
}
