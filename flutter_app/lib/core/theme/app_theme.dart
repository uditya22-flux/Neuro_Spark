import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel Light Theme Colors (Sensory-Friendly, Low Stimulation)
  static const Color lightBackground = Color(0xFFFAF9F6); // Warm off-white
  static const Color lightSurface = Color(0xFFF0EFEA);    // Muted linen
  static const Color lightPrimary = Color(0xFF6B8A7A);    // Soft sage/muted green
  static const Color lightSecondary = Color(0xFFB4C3B2);  // Soft pastel green
  static const Color lightText = Color(0xFF2C3E50);       // Soft slate gray
  static const Color lightTextMuted = Color(0xFF6B7280);  // Muted gray
  static const Color lightBorder = Color(0xFFE5E7EB);     // Subtle gray border

  // Safe Mode Dark Theme Colors (High-Contrast, Low Stimulation Light Output)
  static const Color darkBackground = Color(0xFF0F172A);  // Deep slate blue/black
  static const Color darkSurface = Color(0xFF1E293B);     // Slate container
  static const Color darkPrimary = Color(0xFFFFD166);     // High contrast soft yellow
  static const Color darkSecondary = Color(0xFF06D6A0);   // High contrast soft green
  static const Color darkText = Color(0xFFF8FAFC);        // Pure white/high contrast
  static const Color darkTextMuted = Color(0xFF94A3B8);   // Muted slate gray
  static const Color darkBorder = Color(0xFF334155);      // Distinct slate border

  static const double borderRadius = 24.0;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: lightText,
        onSurface: lightText,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: lightBorder, width: 1.5),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightText,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightText,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextMuted,
          height: 1.4,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        onPrimary: darkBackground,
        onSecondary: darkText,
        onSurface: darkText,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: darkBorder, width: 2.0),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkText,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextMuted,
          height: 1.4,
        ),
      ),
      useMaterial3: true,
    );
  }
}
