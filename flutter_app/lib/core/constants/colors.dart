import 'package:flutter/material.dart';

class AppColors {
  // Core Surfaces
  static const Color background = Color(0xFF080B16);
  static const Color surface = Color(0xFF11182A);
  static const Color elevatedCard = Color(0xFF171F35);
  static const Color cardBorder = Color(0xFF1F2B4A);
  static const Color cardGlow = Color(0x334F8CFF);

  // Brand Accents
  static const Color primaryBlue = Color(0xFF4F8CFF);
  static const Color violetAccent = Color(0xFF8B5CF6);
  static const Color cyanHighlight = Color(0xFF42D9F5);

  // Typography
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFF9BA8C7);
  static const Color textMuted = Color(0xFF64748B);

  // Status Indicators
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, violetAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyanHighlight, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF182038), Color(0xFF111728)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mountainSkyGradient = LinearGradient(
    colors: [Color(0xFF060810), Color(0xFF0E1528), Color(0xFF161F38)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
