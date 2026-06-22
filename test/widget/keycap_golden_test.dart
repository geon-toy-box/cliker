@Tags(<String>['golden'])
library;

import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed golden surface so the captured pixels are stable across runs.
const Size _surface = Size(360, 360);

/// Hosts [child] centered on the app's dark background under the real
/// [appTheme], filling the whole golden surface.
Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: child),
    ),
  );
}

void main() {
  group('Keycap golden (AC4)', () {
    setUp(() {
      // No ripple is captured: goldens cover the resting and pressed-held cap.
    });

    testWidgets('unpressed Keycap, dark theme + neonCyan', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = _surface;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(const Keycap(ledColor: AppColors.neonCyan, label: 'A')),
      );
      await tester.pump();

      await expectLater(
        find.byType(Keycap),
        matchesGoldenFile('goldens/keycap_unpressed.png'),
      );
    });

    testWidgets('pressed-held Keycap, dark theme + neonCyan', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = _surface;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(const Keycap(ledColor: AppColors.neonCyan, label: 'A')),
      );

      // Hold the cap down and drive the press-down animation to its extreme,
      // then capture while still held (gesture is never released).
      await tester.startGesture(
        tester.getCenter(find.byKey(Keycap.innerCapKey)),
      );
      await tester.pump();
      await tester.pump(Keycap.pressDownDuration);
      // Let the spawned ripple finish so only the pressed cap remains.
      await tester.pump(
        Keycap.rippleDuration + const Duration(milliseconds: 1),
      );
      await tester.pump();

      await expectLater(
        find.byType(Keycap),
        matchesGoldenFile('goldens/keycap_pressed.png'),
      );
    });
  });
}
