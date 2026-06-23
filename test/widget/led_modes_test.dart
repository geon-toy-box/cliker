import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a minimal app under the real [appTheme].
Widget _host(Widget child) {
  return MaterialApp(
    theme: appTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Reads the keycap's live LED glow [BoxShadow] off its inner-cap container.
BoxShadow _glowShadow(WidgetTester tester) {
  final Container cap = tester.widget<Container>(
    find.byKey(Keycap.innerCapKey),
  );
  final BoxDecoration decoration = cap.decoration! as BoxDecoration;
  return decoration.boxShadow!.first;
}

/// The glow color (with its press/flare-driven alpha applied).
Color _glowColor(WidgetTester tester) => _glowShadow(tester).color;

/// The glow alpha in [0, 1]; proxy for "how bright the LED is right now".
double _glowAlpha(WidgetTester tester) => _glowShadow(tester).color.a;

void main() {
  group('AC4: LedMode.rgbCycle cycles the glow hue over time', () {
    testWidgets('the glow color changes as time advances', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchBlue,
            ledMode: LedMode.rgbCycle,
            label: 'A',
          ),
        ),
      );
      await tester.pump();

      final Color first = _glowColor(tester);

      // Advance a quarter of the cycle period — the hue must have moved.
      await tester.pump(Keycap.rgbCycleDuration ~/ 4);
      final Color quarter = _glowColor(tester);

      // Advance another quarter (half-cycle total) — different again.
      await tester.pump(Keycap.rgbCycleDuration ~/ 4);
      final Color half = _glowColor(tester);

      expect(
        quarter.toARGB32() & 0x00FFFFFF,
        isNot(first.toARGB32() & 0x00FFFFFF),
        reason: 'hue should have advanced after a quarter cycle',
      );
      expect(
        half.toARGB32() & 0x00FFFFFF,
        isNot(quarter.toARGB32() & 0x00FFFFFF),
        reason: 'hue should keep advancing',
      );
    });

    testWidgets('a non-cycling mode keeps a steady hue over the same time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchBlue,
            ledMode: LedMode.solid,
            label: 'A',
          ),
        ),
      );
      await tester.pump();

      final int before = _glowColor(tester).toARGB32() & 0x00FFFFFF;
      await tester.pump(Keycap.rgbCycleDuration ~/ 2);
      final int after = _glowColor(tester).toARGB32() & 0x00FFFFFF;

      expect(after, before, reason: 'solid mode must not cycle hue');
      // And it tracks the supplied base color.
      expect(before, AppColors.neonCyan.toARGB32() & 0x00FFFFFF);
    });
  });

  group('AC4: LedMode.reactive brightens on press then decays', () {
    testWidgets('glow intensity rises right after a press', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonGreen,
            stemColor: AppColors.switchBlack,
            ledMode: LedMode.reactive,
            label: 'A',
          ),
        ),
      );
      await tester.pump();

      // Resting intensity (dim baseline).
      final double resting = _glowAlpha(tester);

      // Press down: the reactive flare snaps to full.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Keycap.innerCapKey)),
      );
      await tester.pump();
      final double justPressed = _glowAlpha(tester);

      expect(
        justPressed,
        greaterThan(resting),
        reason: 'a fresh press must brighten the reactive glow',
      );

      // Release and let the flare decay; it must fall back below the peak.
      await gesture.up();
      await tester.pump();
      await tester.pump(Keycap.reactiveDecayDuration);
      final double decayed = _glowAlpha(tester);

      expect(
        decayed,
        lessThan(justPressed),
        reason: 'the flare must decay after release',
      );
    });
  });

  group('backward-compatible default (LedMode.ripple)', () {
    testWidgets('default keycap glows steadily in its base color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonMagenta,
            stemColor: AppColors.switchRed,
            label: 'A',
          ),
        ),
      );
      await tester.pump();

      final int before = _glowColor(tester).toARGB32() & 0x00FFFFFF;
      await tester.pump(Keycap.rgbCycleDuration);
      final int after = _glowColor(tester).toARGB32() & 0x00FFFFFF;

      // No cycling by default, and the hue matches the base color.
      expect(after, before);
      expect(before, AppColors.neonMagenta.toARGB32() & 0x00FFFFFF);
    });
  });
}
