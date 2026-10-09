import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from the initial design
  static const Color scaffoldBackground = Color(0xFF041510); // Deep emerald dark
  static const Color brandGreen = Color(0xFF34d399); // Bright emerald green
  static const Color surfaceColor = Color(0xFF081F17); // Slightly lighter emerald for cards
  static const Color surfaceColorLight = Color(0xFF0F2936); 
  
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color youtubeRed = Color(0xFFEF4444);
  static const Color appleSilver = Colors.white;

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: brandGreen,
        secondary: brandGreen,
        surface: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen.withValues(alpha: 0.15),
          foregroundColor: brandGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
