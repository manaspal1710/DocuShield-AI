import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryCyan = Color(0xFF00BCD4);
  static const Color backgroundNavy = Color(0xFF0A0E21);
  static const Color surfaceNavy = Color(0xFF1A1F36);
  static const Color cardNavy = Color(0xFF1E2340);
  static const Color accentTeal = Color(0xFF00E5FF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: backgroundNavy,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentTeal,
        surface: surfaceNavy,
        background: backgroundNavy,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 5,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCyan,
          side: const BorderSide(color: primaryCyan, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceNavy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 2),
        ),
      ),
    );
  }
}
