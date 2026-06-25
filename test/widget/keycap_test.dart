import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/led_ripple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a minimal app under the real [appTheme] so the widget is
/// rendered exactly as it ships.
Widget _host(Widget child) {
  return MaterialApp(
    theme: appTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Reads the smallest x-scale among the [Transform] ancestors of the cap. The
/// press is a uniform scale (the translate ancestor leaves the x-diagonal at
/// 1.0), so this returns 1.0 at rest and drops below 1.0 while held — which is
/// how we observe the pressed visual state.
double _pressScale(WidgetTester tester) {
  final Iterable<Transform> transforms = tester.widgetList<Transform>(
    find.ancestor(
      of: find.byKey(Keycap.innerCapKey),
      matching: find.byType(Transform),
    ),
  );
  return transforms
      .map((Transform t) => t.transform.storage[0])
      .reduce((double a, double b) => a < b ? a : b);
}

void main() {
  group('Keycap', () {
    testWidgets('AC1: renders under appTheme honoring its Key', (
      WidgetTester tester,
    ) async {
      const Key capKey = Key('the-keycap');
      await tester.pumpWidget(
        _host(
          const Keycap(
            key: capKey,
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchBlue,
            label: 'A',
          ),
        ),
      );

      expect(find.byKey(capKey), findsOneWidget);
      expect(find.byType(Keycap), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      // No exceptions during layout/paint.
      expect(tester.takeException(), isNull);
    });

    testWidgets('AC5: stemColor reaches the switch-layer painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchRed,
            label: 'A',
          ),
        ),
      );

      final CustomPaint paint = tester.widget<CustomPaint>(
        find.byKey(Keycap.switchLayerKey),
      );
      final KeycapSwitchPainter painter = paint.painter! as KeycapSwitchPainter;
      expect(painter.stemColor, AppColors.switchRed);

      // A different switch repaints with a different stem color.
      await tester.pumpWidget(
        _host(
          const Keycap(
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchBlue,
            label: 'A',
          ),
        ),
      );
      final KeycapSwitchPainter repainted =
          tester.widget<CustomPaint>(find.byKey(Keycap.switchLayerKey)).painter!
              as KeycapSwitchPainter;
      expect(repainted.stemColor, AppColors.switchBlue);
    });

    testWidgets(
      'AC2: tapDown fires onPressDown once, tapUp fires onPressUp once, '
      'and the cap enters a pressed visual state while held',
      (WidgetTester tester) async {
        int downCount = 0;
        int upCount = 0;

        await tester.pumpWidget(
          _host(
            Keycap(
              ledColor: AppColors.neonCyan,
              stemColor: AppColors.switchBlue,
              label: 'A',
              onPressDown: (double? _) => downCount++,
              onPressUp: () => upCount++,
            ),
          ),
        );

        // At rest the press transform is identity (scale 1.0).
        expect(_pressScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        // Let the press-down animation run to its pressed extreme.
        await tester.pump();
        await tester.pump(Keycap.pressDownDuration);

        expect(downCount, 1);
        expect(upCount, 0);
        // Pressed: the cap has shrunk below its resting scale.
        expect(_pressScale(tester), lessThan(1.0));

        await gesture.up();
        // Drive the snap-up animation back to rest.
        await tester.pump();
        await tester.pump(Keycap.pressUpDuration);

        expect(downCount, 1);
        expect(upCount, 1);
        expect(_pressScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));
      },
    );

    testWidgets(
      'AC3: each press adds exactly one LedRipple, gone after rippleDuration',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            const Keycap(
              ledColor: AppColors.neonCyan,
              stemColor: AppColors.switchBlue,
              label: 'A',
            ),
          ),
        );

        // No ripple before any interaction.
        expect(find.byType(LedRipple), findsNothing);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        await tester.pump();

        // Exactly one ripple was spawned by the press.
        expect(find.byType(LedRipple), findsOneWidget);

        await gesture.up();
        await tester.pump();
        // Still exactly one (release does not spawn another).
        expect(find.byType(LedRipple), findsOneWidget);

        // After the ripple's full lifetime elapses it removes itself — no leak.
        await tester.pump(
          Keycap.rippleDuration + const Duration(milliseconds: 1),
        );
        await tester.pump();
        expect(find.byType(LedRipple), findsNothing);
      },
    );

    testWidgets('AC2/AC3: a second press fires callbacks and ripple again', (
      WidgetTester tester,
    ) async {
      int downCount = 0;
      int upCount = 0;

      await tester.pumpWidget(
        _host(
          Keycap(
            ledColor: AppColors.neonMagenta,
            stemColor: AppColors.switchRed,
            onPressDown: (double? _) => downCount++,
            onPressUp: () => upCount++,
          ),
        ),
      );

      Future<void> tapOnce() async {
        final TestGesture g = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        await tester.pump();
        await g.up();
        await tester.pump();
        // Let the ripple finish so it does not bleed into the next press.
        await tester.pump(
          Keycap.rippleDuration + const Duration(milliseconds: 1),
        );
        await tester.pump();
      }

      await tapOnce();
      await tapOnce();

      expect(downCount, 2);
      expect(upCount, 2);
      expect(find.byType(LedRipple), findsNothing);
    });

    testWidgets(
      'onPressDown is handed a force argument (null when the test pointer '
      'reports no pressure range)',
      (WidgetTester tester) async {
        final List<double?> forces = <double?>[];

        await tester.pumpWidget(
          _host(
            Keycap(
              ledColor: AppColors.neonCyan,
              stemColor: AppColors.switchBlue,
              onPressDown: forces.add,
            ),
          ),
        );

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // The callback fired once; the synthetic pointer has no pressure range
        // (pressureMin == pressureMax), so force normalizes to null.
        expect(forces, hasLength(1));
        expect(forces.single, isNull);
      },
    );

    testWidgets(
      'onPressDown reports the normalized force when the pointer has a real '
      'pressure range',
      (WidgetTester tester) async {
        final List<double?> forces = <double?>[];

        await tester.pumpWidget(
          _host(
            Keycap(
              ledColor: AppColors.neonCyan,
              stemColor: AppColors.switchBlue,
              onPressDown: forces.add,
            ),
          ),
        );

        // Drive a pointer-down carrying a genuine pressure range (0..1 @ 0.8),
        // unlike tester.startGesture which always collapses the range to 1..1.
        final Offset center = tester.getCenter(find.byKey(Keycap.innerCapKey));
        final TestGesture gesture = await tester.createGesture();
        await gesture.downWithCustomEvent(
          center,
          PointerDownEvent(
            position: center,
            pressure: 0.8,
            pressureMin: 0.0,
            pressureMax: 1.0,
          ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // 0.8 normalized across [0, 1] is 0.8 — proves the pressure-capture
        // wiring (Listener → normalizeForce → onPressDown), not just the null
        // fallback.
        expect(forces, hasLength(1));
        expect(forces.single, isNotNull);
        expect(forces.single!, moreOrLessEquals(0.8, epsilon: 0.001));
      },
    );

    testWidgets('onTapCancel still balances the press with onPressUp', (
      WidgetTester tester,
    ) async {
      int downCount = 0;
      int upCount = 0;

      await tester.pumpWidget(
        _host(
          Keycap(
            ledColor: AppColors.neonCyan,
            stemColor: AppColors.switchBlue,
            onPressDown: (double? _) => downCount++,
            onPressUp: () => upCount++,
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Keycap.innerCapKey)),
      );
      await tester.pump();
      expect(downCount, 1);

      // Move far enough to turn the tap into a cancel, then lift.
      await gesture.moveBy(const Offset(0, 600));
      await gesture.up();
      await tester.pump(Keycap.pressUpDuration);

      expect(downCount, 1);
      expect(upCount, 1);
    });
  });
}
