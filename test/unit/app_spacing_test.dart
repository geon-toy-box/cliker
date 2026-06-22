import 'package:cliker/theme/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing (AC3)', () {
    test('spacing scale values', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });
  });

  group('AppRadius (AC3)', () {
    test('radius scale values', () {
      expect(AppRadius.sm, 8);
      expect(AppRadius.md, 14);
      expect(AppRadius.lg, 20);
      expect(AppRadius.pill, 999);
    });
  });
}
