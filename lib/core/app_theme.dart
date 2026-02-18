import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ShahiChai Royal Palette
  static const Color royalMaroon = Color(0xFF0A4E2B); 
  static const Color deepGreen = Color(0xFF2D6A4F);
  static const Color goldAccent = Color(0xFFD4A373);
  static const Color creamBg = Color(0xFFFEFAE0);
  static const Color textDark = Color(0xFF1B263B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: royalMaroon,
        background: const Color(0xFFF8F9FA),
        surface: Colors.white,
        primary: royalMaroon,
        secondary: deepGreen, 
        tertiary: goldAccent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textDark,
        displayColor: royalMaroon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.poppins(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalMaroon,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: goldAccent.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: goldAccent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: royalMaroon, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Legacy Aliases for Compatibility
  static const Color primaryGreen = deepGreen; // Or royalMaroon based on preference
  static const Color darkGreen = royalMaroon;
  static const Color teaLatte = creamBg;
  static const Color accentOrange = goldAccent;
}
