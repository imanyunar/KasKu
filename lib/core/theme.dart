import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Ultra-Modern Fintech Color Palette ---
  static const Color maroon = Color(0xFF7A0016);        // Deep Executive Crimson
  static const Color maroonDark = Color(0xFF4A000D);    // Midnight Velvet Maroon
  static const Color maroonLight = Color(0xFF9E1B32);   // Rose Maroon Accent
  
  static const Color gold = Color(0xFFE5A93C);          // Champagne Gold
  static const Color goldLight = Color(0xFFFBE4B5);     // Soft Gold Glow
  
  static const Color background = Color(0xFFF4F6FB);    // Premium Cool Grey-Blue Slate
  static const Color surface = Colors.white;            // Pure White Card Surface
  static const Color cardBorder = Color(0xFFE2E8F0);        // Slate 200 Border
  
  static const Color textDark = Color(0xFF0F172A);      // Slate 900
  static const Color textMuted = Color(0xFF64748B);     // Slate 500
  static const Color textLight = Colors.white;
  
  // Functional Colors (Modern Vibrant Tones)
  static const Color green = Color(0xFF059669);         // Emerald 600
  static const Color greenSoft = Color(0xFFECFDF5);     // Emerald 50
  
  static const Color red = Color(0xFFDC2626);           // Crimson Red 600
  static const Color redSoft = Color(0xFFFEF2F2);       // Red 50

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B1527), Color(0xFF500813)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

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
      
      // Tipografi Premium (Plus Jakarta Sans)
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -1,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
      ),

      // AppBar Glassmorphic / Modern
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: maroon, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: maroon,
          letterSpacing: -0.5,
        ),
      ),

      // Tombol Primary Pill
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          minimumSize: const Size.fromHeight(56),
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          shadowColor: maroon.withOpacity(0.35),
        ),
      ),
    );
  }
}
