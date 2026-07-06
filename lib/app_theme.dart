import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors — Tadika Aqil Miqail logo ─────────────────
  /// Dominant royal blue from the book/building icon and school name
  static const Color schoolBlue      = Color(0xFF1B5DA6);
  /// Warm orange from the open-book page accent and subtitle text
  static const Color schoolOrange    = Color(0xFFF5841F);
  /// Deeper navy used for headings and high-contrast text
  static const Color schoolDarkBlue  = Color(0xFF123D6B);
  /// Very light blue tint — chips, selected state backgrounds
  static const Color schoolLightBlue = Color(0xFFD4E6F8);
  /// Light orange tint — warning badges, accent surfaces
  static const Color schoolLightOrange = Color(0xFFFEEDD8);

  // ── Canvas / Background ─────────────────────────────────────
  /// Main scaffold background — cool off-white with a breath of blue
  static const Color canvasBase      = Color(0xFFF2F6FC);
  /// Near-white ambient surface used behind cards
  static const Color ambientOffWhite = Color(0xFFFAFCFF);

  // ── Surface / Cards ─────────────────────────────────────────
  static const Color cardBackground     = Color(0xFFFFFFFF);
  /// Subtle blue-tinted divider / card border
  static const Color subtleGrayBoundary = Color(0xFFE4EDF8);

  // ── Primary and Accent (role-named, map to brand) ───────────
  static const Color primaryActive   = schoolBlue;
  static const Color secondaryAccent = schoolOrange;

  // ── Legacy tints kept for backwards-compatibility ───────────
  static const Color warmPink         = Color(0xFFE8D1D1);
  static const Color aestheticWoodTan = Color(0xFFF2E8DA);

  // ── Text Colors ──────────────────────────────────────────────
  /// Deep blue-slate — main body and label text
  static const Color textCore  = Color(0xFF1A2D45);
  /// Medium slate-blue — secondary, hints, timestamps
  static const Color textMuted = Color(0xFF5F7A99);

  // ── Shadows ──────────────────────────────────────────────────
  static final List<BoxShadow> iosBoxShadow = [
    BoxShadow(
      color: const Color(0xFF1B5DA6).withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  // ── Backwards-compatible aliases (const — usable in const contexts) ──
  static const Color primaryColor   = primaryActive;
  static const Color textLightColor = textMuted;
  static const Color textColor      = textCore;

  // ════════════════════════════════════════════════════════════
  //  Light Theme
  // ════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      primaryColor: primaryActive,
      scaffoldBackgroundColor: canvasBase,

      colorScheme: const ColorScheme.light(
        primary: schoolBlue,
        secondary: schoolOrange,
        surface: cardBackground,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCore,
        // Tonal surfaces derived from blue
        primaryContainer: schoolLightBlue,
        secondaryContainer: schoolLightOrange,
        onPrimaryContainer: schoolDarkBlue,
        onSecondaryContainer: Color(0xFF7A3A00),
      ),

      fontFamily: 'Inter',

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: schoolDarkBlue,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: schoolDarkBlue,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: schoolDarkBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: schoolDarkBlue,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textCore,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textCore,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textCore,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textCore,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: canvasBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: schoolDarkBlue),
        titleTextStyle: TextStyle(
          color: schoolDarkBlue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: schoolBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: schoolBlue,
          side: const BorderSide(color: schoolBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: schoolBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: subtleGrayBoundary,
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        hintStyle: TextStyle(color: textMuted.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: subtleGrayBoundary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: subtleGrayBoundary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: schoolBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
      ),

      chipTheme: const ChipThemeData(
        backgroundColor: schoolLightBlue,
        labelStyle: TextStyle(
          color: schoolDarkBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: subtleGrayBoundary,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: schoolBlue,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: schoolDarkBlue,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}