import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors token ARGB values (AC1)', () {
    test('background / surface tokens', () {
      expect(AppColors.bg.toARGB32(), 0xFF0A0A0F);
      expect(AppColors.surface.toARGB32(), 0xFF15151F);
      expect(AppColors.surfaceHi.toARGB32(), 0xFF1F1F2E);
    });

    test('keycap tokens', () {
      expect(AppColors.keycapBase.toARGB32(), 0xFF1E1E28);
      expect(AppColors.keycapTop.toARGB32(), 0xFF2A2A3A);
      expect(AppColors.keycapEdge.toARGB32(), 0xFF101018);
    });

    test('text tokens', () {
      expect(AppColors.textPrimary.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.textMuted.toARGB32(), 0xFF8A8A99);
    });

    test('neon LED tokens', () {
      expect(AppColors.neonCyan.toARGB32(), 0xFF00E5FF);
      expect(AppColors.neonMagenta.toARGB32(), 0xFFFF2D95);
      expect(AppColors.neonGreen.toARGB32(), 0xFF39FF14);
      expect(AppColors.neonPurple.toARGB32(), 0xFFB026FF);
      expect(AppColors.neonOrange.toARGB32(), 0xFFFF6B1A);
      expect(AppColors.neonYellow.toARGB32(), 0xFFFFE600);
    });

    test('switch-stem tokens', () {
      expect(AppColors.switchBlue.toARGB32(), 0xFF3B82F6);
      expect(AppColors.switchBrown.toARGB32(), 0xFF92400E);
      expect(AppColors.switchRed.toARGB32(), 0xFFEF4444);
      expect(AppColors.switchBlack.toARGB32(), 0xFF111827);
    });

    test('accentDefault is neonCyan', () {
      expect(AppColors.accentDefault.toARGB32(), 0xFF00E5FF);
      expect(AppColors.accentDefault, same(AppColors.neonCyan));
    });
  });

  group('AppColors.ledPalette (AC4)', () {
    test('contains exactly the six neon colors in canonical order', () {
      expect(AppColors.ledPalette, hasLength(6));
      expect(AppColors.ledPalette, <Color>[
        AppColors.neonCyan,
        AppColors.neonMagenta,
        AppColors.neonGreen,
        AppColors.neonPurple,
        AppColors.neonOrange,
        AppColors.neonYellow,
      ]);
    });

    test('palette ARGB values match spec in order', () {
      final List<int> argb = AppColors.ledPalette
          .map((Color c) => c.toARGB32())
          .toList();
      expect(argb, <int>[
        0xFF00E5FF,
        0xFFFF2D95,
        0xFF39FF14,
        0xFFB026FF,
        0xFFFF6B1A,
        0xFFFFE600,
      ]);
    });
  });
}
