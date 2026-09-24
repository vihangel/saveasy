import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta extraída do protótipo no Figma.
abstract final class AppColors {
  static const orange = Color(0xFFFA7E2A);
  static const primary = Color(0xFF6176ED);
  static const primaryLight = Color(0xFFE9EDFD);
  static const surface = Color(0xFFF5F6F7);
  static const background = Colors.white;
  static const textDark = Color(0xFF121526);
  static const text = Color(0xFF414451);
  static const textMuted = Color(0xFF8F92A1);
  static const link = Color(0xFF519DE0);
  static const border = Color(0xFFE6E8EC);
  static const success = Color(0xFF2EB67D);
  static const danger = Color(0xFFE5484D);
  static const gold = Color(0xFFFFBC22);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.orange,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    final body = GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.textDark);
    final headline = GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: AppColors.textDark);

    return base.copyWith(
      textTheme: body.copyWith(
        headlineMedium: headline.copyWith(fontSize: 24),
        headlineSmall: headline.copyWith(fontSize: 22),
        titleLarge: headline.copyWith(fontSize: 20),
        titleMedium: headline.copyWith(fontSize: 16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: headline.copyWith(fontSize: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.text),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600, fontSize: 15),
        dividerColor: AppColors.border,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
