import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App colour palette — PropCare Governance.
class AppColors {
  AppColors._();

  // ── Primary blue family (#1a73e8) ──────────────────────────────────────────
  static const Color primary     = Color(0xFF1A73E8); // Google-style blue
  static const Color primaryDark = Color(0xFF1557B0); // deeper blue
  static const Color primaryLight= Color(0xFF4A9DF4); // lighter blue

  // ── Secondary (navy) ───────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF0A1931); // deep navy
  static const Color secondaryLight = Color(0xFF1B3A6B);
  static const Color surface        = Color(0xFF132240);

  // ── On-colours ─────────────────────────────────────────────────────────────
  static const Color onPrimary   = Colors.white;
  static const Color onSecondary = Colors.white;

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color grey      = Color(0xFF5A5A5A);
  static const Color greyLight = Color(0xFFE8E8E8);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color error      = Color(0xFFE74C3C);
  static const Color success    = Color(0xFF27AE60);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBg     = Colors.white;
}

/// Centralised theme configuration for PropCare Governance.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.cardBg,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
    );
  }
}
