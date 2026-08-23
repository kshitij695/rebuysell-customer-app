import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2BB584);
  static const Color darkGreen = Color(0xFF1E8761);
  static const Color accentOrange = Color(0xFFFF6B4A);
  static const Color backgroundSlate = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get theme {
    final baseFont = GoogleFonts.outfitTextTheme();
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundSlate,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentOrange,
      ),
      textTheme: baseFont.copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textMain),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textMain),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textMain),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textMain),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textMain),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textMain),
        bodyLarge: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: textMain),
        bodyMedium: GoogleFonts.outfit(fontWeight: FontWeight.w400, color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
