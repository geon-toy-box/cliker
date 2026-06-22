import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appTheme() (AC2)', () {
    final ThemeData theme = appTheme();

    test('is a dark theme', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('scaffold background is AppColors.bg', () {
      expect(theme.scaffoldBackgroundColor.toARGB32(), AppColors.bg.toARGB32());
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
    });

    test('colorScheme.primary is exactly neonCyan', () {
      expect(theme.colorScheme.primary, AppColors.neonCyan);
      expect(theme.colorScheme.primary.toARGB32(), 0xFF00E5FF);
    });

    test('colorScheme.surface and onSurface match tokens', () {
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.onSurface, AppColors.textPrimary);
    });

    test('colorScheme brightness is dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });
}
