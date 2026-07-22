import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Modern Color Palette ---
  static const Color maroon = Color(0xFF800000); // Brand Accent
  static const Color gold = Color(0xFFFFB300);   // Brand Accent Secondary
  
  static const Color background = Color(0xFFF8FAFC); // Sangat modern (Slate 50)
  static const Color surface = Colors.white;
  
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Fungsional (Lebih vibrant dan modern)
  static const Color green = Color(0xFF10B981); // Emerald 500
  static const Color red = Color(0xFFEF4444);   // Red 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: maroon,
        primary: maroon,
        secondary: gold,
        surface: surface,
        error: red,
      ),
      
      // Tipografi Sangat Modern (Outfit)
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -1,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),

      // AppBar Transparan/Modern
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: maroon),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: maroon,
          letterSpacing: -0.5,
        ),
      ),

      // Tombol Pill-Shaped yang Sangat Modern
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill shape
          ),
          shadowColor: maroon.withOpacity(0.5),
        ),
      ),
    );
  }
}
