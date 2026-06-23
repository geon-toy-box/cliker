import 'package:cliker/theme/app_theme.dart';
import 'package:cliker/widgets/rgb_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts the wheel under the real [appTheme] at a known size.
Widget _host(Widget child) {
  return MaterialApp(
    theme: appTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('RgbWheel widget interaction', () {
    testWidgets('renders honoring its key and current color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(RgbWheel(color: const Color(0xFFFF0000), onColorChanged: (_) {})),
      );

      expect(find.byKey(RgbWheel.wheelKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the right edge emits a new hue (~green/cyan side)', (
      WidgetTester tester,
    ) async {
      Color? picked;
      await tester.pumpWidget(
        _host(
          RgbWheel(
            // Start at red (hue 0 / top).
            color: const Color(0xFFFF0000),
            onColorChanged: (Color c) => picked = c,
            size: 200,
          ),
        ),
      );

      final Rect box = tester.getRect(find.byKey(RgbWheel.wheelKey));
      // Tap on the right edge → hue ≈ 90°.
      await tester.tapAt(Offset(box.right - 2, box.center.dy));
      await tester.pump();

      expect(picked, isNotNull);
      final double hue = HSVColor.fromColor(picked!).hue;
      // Right edge is ~90°; allow slack for the 2px inset.
      expect(hue, greaterThan(70));
      expect(hue, lessThan(110));
      // And the emitted color differs from the starting red.
      expect(picked!.toARGB32(), isNot(const Color(0xFFFF0000).toARGB32()));
    });

    testWidgets('dragging across the ring emits multiple distinct colors', (
      WidgetTester tester,
    ) async {
      final List<Color> emitted = <Color>[];
      await tester.pumpWidget(
        _host(
          RgbWheel(
            color: const Color(0xFFFF0000),
            onColorChanged: emitted.add,
            size: 200,
          ),
        ),
      );

      final Rect box = tester.getRect(find.byKey(RgbWheel.wheelKey));
      final TestGesture g = await tester.startGesture(
        Offset(box.center.dx, box.top + 4),
      );
      await tester.pump();
      await g.moveTo(Offset(box.right - 4, box.center.dy));
      await tester.pump();
      await g.moveTo(Offset(box.center.dx, box.bottom - 4));
      await tester.pump();
      await g.up();

      // Dragging across the ring emits several colors spanning distinct hues
      // (the exact count depends on pointer-event coalescing, so assert on the
      // hue spread rather than a precise emission count).
      expect(emitted.length, greaterThanOrEqualTo(2));
      final Set<int> distinctHues = emitted
          .map((Color c) => HSVColor.fromColor(c).hue.round())
          .toSet();
      expect(distinctHues.length, greaterThanOrEqualTo(2));
    });
  });
}
