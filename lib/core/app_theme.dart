import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ShahiChai Royal Palette
  static const Color royalMaroon = Color(0xFF0A4E2B); // Now Green as requested
  static const Color deepGreen = Color(0xFF2D6A4F);
  static const Color goldAccent = Color(0xFFD4A373);
  static const Color creamBg = Color(0xFFFEFAE0);
  static const Color textDark = Color(0xFF1B263B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: royalMaroon,
        background: creamBg,
        surface: Colors.white,
        primary: royalMaroon,
        secondary: deepGreen,
        tertiary: goldAccent,
      ),
      textTheme: GoogleFonts.cormorantGaramondTextTheme().apply(
        bodyColor: textDark,
        displayColor: royalMaroon,
      ).copyWith(
        titleLarge: GoogleFonts.cormorantGaramond(
          fontWeight: FontWeight.bold, 
          fontSize: 28,
        ),
        bodyMedium: GoogleFonts.lato(fontSize: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: royalMaroon),
        titleTextStyle: TextStyle(
          color: royalMaroon,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'CormorantGaramond',
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royalMaroon,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: royalMaroon.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
