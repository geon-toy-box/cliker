import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// The single dark, neon-RGB themed [ThemeData] for cliker.
///
/// The [ColorScheme] is constructed explicitly (not via [ColorScheme.fromSeed])
/// so the palette is exact and predictable: `colorScheme.primary` is precisely
/// [AppColors.neonCyan].
ThemeData appTheme() {
  const ColorScheme colorScheme = ColorScheme.dark(
    primary: AppColors.neonCyan,
    onPrimary: AppColors.bg,
    secondary: AppColors.neonMagenta,
    onSecondary: AppColors.bg,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.switchRed,
    onError: AppColors.textPrimary,
  );

  final TextTheme textTheme = _buildTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: AppColors.surfaceHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
  );
}

/// Readable text theme built on [AppColors.textPrimary] (default) and
/// [AppColors.textMuted] (secondary/body) tones.
TextTheme _buildTextTheme() {
  const TextTheme base = Typography.whiteMountainView;
  return base
      .apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      )
      .copyWith(
        bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textMuted),
        bodySmall: base.bodySmall?.copyWith(color: AppColors.textMuted),
        labelMedium: base.labelMedium?.copyWith(color: AppColors.textMuted),
      );
}
