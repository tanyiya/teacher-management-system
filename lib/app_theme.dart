import 'package:flutter/material.dart';

class AppTheme {
  // Canvas Base Background
  static const Color canvasBase = Color(0xFFF5F5F3);
  static const Color ambientOffWhite = Color(0xFFFAF9F6);

  // Accent Container Cards
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color subtleGrayBoundary = Color(0xFFF0EFEC);

  // Primary and Accent Colors
  static const Color primaryActive = Color(0xFFB2C2B2);
  static const Color secondaryAccent = Color(0xFFBCCCDC);
  static const Color warmPink = Color(0xFFE8D1D1);
  static const Color aestheticWoodTan = Color(0xFFF2E8DA);

  // Text Colors
  static const Color textCore = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF8E8E8E);

  // iOS-inspired Shadow
  static final List<BoxShadow> iosBoxShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  // Backwards-compatible aliases used across the app (const so usable in const contexts)
  static const Color primaryColor = primaryActive;
  static const Color textLightColor = textMuted;
  static const Color textColor = textCore;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      primaryColor: primaryActive,
      scaffoldBackgroundColor: canvasBase,

      colorScheme: const ColorScheme.light(
        primary: primaryActive,
        secondary: secondaryAccent,
        surface: cardBackground,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textCore,
      ),

      fontFamily: 'Inter',

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textCore,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textCore,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textCore,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textCore,
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
        iconTheme: IconThemeData(color: textCore),
        titleTextStyle: TextStyle(
          color: textCore,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryActive,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
    );
  }
}