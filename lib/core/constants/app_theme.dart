import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark, letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark, letterSpacing: -0.3,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w400,
            color: AppColors.textPrimaryDark,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryDark,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400,
            color: AppColors.textTertiaryDark,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0.0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDark, width: 1),
          ),
          margin: const EdgeInsets.all(0.0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: GoogleFonts.inter(
            color: AppColors.textTertiaryDark, fontSize: 14,
          ),
          labelStyle: GoogleFonts.inter(
            color: AppColors.textSecondaryDark, fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0.0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardDark,
          labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiaryDark,
          type: BottomNavigationBarType.fixed,
          elevation: 0.0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderDark,
          thickness: 1,
          space: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.cardDark,
          contentTextStyle: GoogleFonts.inter(
            color: AppColors.textPrimaryDark, fontSize: 14,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
      );
}
