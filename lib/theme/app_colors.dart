import 'package:flutter/painting.dart';

/// Dark + neon-RGB ("gaming keyboard LED") color tokens for cliker.
///
/// Every value is an explicit 32-bit ARGB constant so the palette is exact and
/// auditable. Tokens are grouped by role: backgrounds/surfaces, keycap shading,
/// text, neon LED palette, and switch-stem colors.
abstract final class AppColors {
  // Backgrounds / surfaces.
  static const Color bg = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF15151F);
  static const Color surfaceHi = Color(0xFF1F1F2E);

  // Keycap shading.
  static const Color keycapBase = Color(0xFF1E1E28);
  static const Color keycapTop = Color(0xFF2A2A3A);
  static const Color keycapEdge = Color(0xFF101018);

  // Text.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A8A99);

  // Neon LED palette.
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonMagenta = Color(0xFFFF2D95);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonPurple = Color(0xFFB026FF);
  static const Color neonOrange = Color(0xFFFF6B1A);
  static const Color neonYellow = Color(0xFFFFE600);

  // Switch-stem colors.
  static const Color switchBlue = Color(0xFF3B82F6);
  static const Color switchBrown = Color(0xFF92400E);
  static const Color switchRed = Color(0xFFEF4444);
  static const Color switchBlack = Color(0xFF111827);
  static const Color switchWhite = Color(0xFFE5E7EB);
  static const Color switchGray = Color(0xFF6B7280);
  static const Color switchClear = Color(0xFFD1D5DB);
  static const Color switchSilentRed = Color(0xFFF87171);
  static const Color switchSilentBlack = Color(0xFF374151);
  static const Color switchSpeedSilver = Color(0xFFC0C7D0);
  static const Color switchDarkGray = Color(0xFF4B5563);

  /// Default LED accent color.
  static const Color accentDefault = neonCyan;

  /// The neon LED palette in canonical order. Used wherever a cycling or
  /// selectable LED color set is needed.
  static const List<Color> ledPalette = <Color>[
    neonCyan,
    neonMagenta,
    neonGreen,
    neonPurple,
    neonOrange,
    neonYellow,
  ];
}
