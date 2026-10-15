import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme defines the central theme tokens, typography, and styles
/// directly mirroring the web application (Landing Page + Valuation Suite).
class AppTheme {
  // ── Palette: Backgrounds & Surfaces (Website matching) ──────────────
  /// Web dark background: #05080F (rich slate-navy from LandingPage.jsx)
  static const Color scaffoldBackground = Color(0xFF05080F);
  
  /// Web main container / card background: #0B101A
  static const Color cardBackground = Color(0xFF0B101A);
  
  /// Surface secondary: #0F172A (Slate-900 used in website headers & panels)
  static const Color surfaceColor = Color(0xFF0F172A);
  
  /// Surface elevated / interactive: #1E293B (Slate-800 for chips & inputs)
  static const Color surfaceColorElevated = Color(0xFF1E293B);

  // ── Palette: Borders & Dividers ─────────────────────────────────────
  /// Web border color: #1A2333 (used across all web cards & input borders)
  static const Color borderColor = Color(0xFF1A2333);
  
  /// Subtle border: #334155 (Slate-700)
  static const Color borderColorSubtle = Color(0xFF334155);

  // ── Palette: Brand & Accents ────────────────────────────────────────
  /// Primary Emerald Green: #10B981 (Emerald-500 from tailwind config)
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color brandGreen = Color(0xFF10B981); // Alias for consistency
  
  /// Bright Emerald: #34D399 (Emerald-400)
  static const Color emeraldLight = Color(0xFF34D399);
  
  /// Deep Emerald: #059669 (Emerald-600)
  static const Color emeraldDark = Color(0xFF059669);
  
  /// Web Electric Cyan Accent: #00E5FF (used in logo "Calculator" & glowing badges)
  static const Color brandCyan = Color(0xFF00E5FF);
  static const Color cyanAccent = Color(0xFF00E5FF);
  
  /// Web Blue Accent: #2563EB / #3B82F6 (Option 1 & CTA buttons)
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color blueAccentLight = Color(0xFF3B82F6);

  // ── Palette: Platform Specific ──────────────────────────────────────
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color youtubeRed = Color(0xFFFF0000);
  static const Color appleSilver = Colors.white;
  static const Color appleRed = Color(0xFFFA243C);

  // ── Palette: Typography & Content ───────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color textMuted = Color(0xFF64748B);     // Slate-500

  // ── Typography Helpers (Inter matching website typography) ─────────
  static TextStyle get displayLarge => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle get statNumber => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get badgeText => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  // ── Box Decorations matching website design ─────────────────────────
  /// Main website card decoration (Dark surface with #1A2333 border and soft shadow)
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Elevated card decoration for inner containers
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor),
  );

  /// Glowing card decoration for highlighted sections (e.g. logo, primary valuation)
  static BoxDecoration glowCardDecoration({Color glowColor = brandCyan, double radius = 24}) => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: glowColor.withValues(alpha: 0.3)),
    boxShadow: [
      BoxShadow(
        color: glowColor.withValues(alpha: 0.12),
        blurRadius: 24,
        spreadRadius: 2,
      ),
    ],
  );

  /// Standard badge container decoration
  static BoxDecoration badgeDecoration({Color color = brandCyan, double radius = 8}) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withValues(alpha: 0.25)),
  );

  // ── ThemeData ───────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardBackground,
      canvasColor: scaffoldBackground,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: brandCyan,
        surface: cardBackground,
        error: Color(0xFFEF4444),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: brandCyan,
        unselectedItemColor: textMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scaffoldBackground,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: surfaceColorElevated,
        thumbColor: primaryGreen,
        overlayColor: primaryGreen.withValues(alpha: 0.2),
        trackHeight: 4,
      ),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
