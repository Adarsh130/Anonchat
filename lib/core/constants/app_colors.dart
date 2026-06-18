import 'package:flutter/material.dart';

class AppColors {
  // Deep space background
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceGlass = Color(0x4D1E293B); // Transparent glassmorphic surface
  
  // Neon Cyber Accents
  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color primaryGlow = Color(0x338B5CF6); // Glow opacity
  
  static const Color secondary = Color(0xFF06B6D4); // Cyan 500
  static const Color secondaryGlow = Color(0x3306B6D4); // Glow opacity
  
  // Status Colors
  static const Color online = Color(0xFF10B981); // Emerald 500
  static const Color success = Color(0xFF10B981);
  static const Color offline = Color(0xFF64748B); // Slate 500
  static const Color error = Color(0xFFEF4444); // Red 500
  
  // Text & Borders
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0x3394A3B8); // Low opacity border
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGlassGradient = LinearGradient(
    colors: [
      Color(0x26FFFFFF),
      Color(0x0AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphic container decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 18.0,
    Color? fillColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: fillColor ?? const Color(0x261E293B), // frosted glass surface
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? const Color(0x1AFFFFFF), // white glass outline
        width: 1.2,
      ),
    );
  }
}
