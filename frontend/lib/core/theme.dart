// ============================================================
//  theme.dart
//  Premium "Soft UI / Aviation" design system.
//  Import this and pass AppTheme.light() to MaterialApp.theme.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Color Palette ────────────────────────────────────
class AppColors {
  AppColors._();

  /// Main app scaffold background — off-white/light grey
  static const Color background = Color(0xFFF5F6F8);

  /// Card / surface background
  static const Color surface = Color(0xFFFFFFFF);

  /// Deep Aviation Blue — primary accent
  static const Color primary = Color(0xFF1D558F);

  /// Slightly lighter blue for gradients / hover states
  static const Color primaryLight = Color(0xFF2A6CB0);

  /// Dark slate — headings and main data text
  static const Color textPrimary = Color(0xFF1C1C1E);

  /// Medium grey — labels and subtle text
  static const Color textSecondary = Color(0xFF8E8E93);

  /// Divider / border lines
  static const Color divider = Color(0xFFE5E5EA);

  /// Input field fill
  static const Color inputFill = Color(0xFFF2F2F7);

  // ── Severity colours ─────────────────────────────────────
  static const Color critical = Color(0xFFFF3B30);
  static const Color criticalSurface = Color(0xFFFFECEB);

  static const Color moderate = Color(0xFFFF9500);
  static const Color moderateSurface = Color(0xFFFFF4E5);

  static const Color low = Color(0xFF34C759);
  static const Color lowSurface = Color(0xFFE6F9EC);

  // ── Status colours ────────────────────────────────────────
  static const Color resolved = Color(0xFF30B0C7);
  static const Color cancelled = Color(0xFF8E8E93);
  static const Color archived = Color(0xFFAEAEB2);
}

// ─── Shared Shape / Decoration Helpers ──────────────────────
class AppShapes {
  AppShapes._();

  /// Standard 24 px radius used on cards, buttons, bottom sheets
  static const double cardRadius = 24.0;

  /// Slightly smaller for inputs
  static const double inputRadius = 16.0;

  /// Badge / chip radius
  static const double badgeRadius = 100.0;

  /// The canonical soft card shadow — floats gently off background
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Deeper shadow for hero elements (stat card, bottom nav)
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static BorderRadius cardBorderRadius =
      BorderRadius.circular(cardRadius);

  static BorderRadius inputBorderRadius =
      BorderRadius.circular(inputRadius);
}

// ─── Main Theme ──────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      // ── Typography (Poppins via google_fonts) ──────────────
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        // Screen headings
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        // Section titles / card flight numbers
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        // Card sub-headings
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Body text
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        // Labels, captions
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),

      // ── Card Theme ─────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // we use custom BoxDecoration shadows
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.cardBorderRadius,
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton (primary CTA) ───────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton (secondary CTA) ────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input / TextFormField ──────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.divider, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.divider, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.critical, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.critical, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.critical,
        ),
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Bottom Navigation ──────────────────────────────────
      // Styling is handled in the custom AppBottomNav widget;
      // this just provides the base.
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}
