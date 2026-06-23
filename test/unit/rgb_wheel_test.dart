import 'package:cliker/widgets/rgb_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double size = 200;
  const double mid = size / 2;

  group('RgbWheel.hueAt maps position → hue (0° top, clockwise)', () {
    test('top is 0° (red)', () {
      expect(
        RgbWheel.hueAt(const Offset(mid, 0), size),
        moreOrLessEquals(0, epsilon: 0.001),
      );
    });

    test('right is 90°', () {
      expect(
        RgbWheel.hueAt(const Offset(size, mid), size),
        moreOrLessEquals(90, epsilon: 0.001),
      );
    });

    test('bottom is 180°', () {
      expect(
        RgbWheel.hueAt(const Offset(mid, size), size),
        moreOrLessEquals(180, epsilon: 0.001),
      );
    });

    test('left is 270°', () {
      expect(
        RgbWheel.hueAt(const Offset(0, mid), size),
        moreOrLessEquals(270, epsilon: 0.001),
      );
    });

    test('all angles fall in [0, 360)', () {
      for (final Offset p in <Offset>[
        const Offset(mid, 0),
        const Offset(size, mid),
        const Offset(mid, size),
        const Offset(0, mid),
        const Offset(size, 0),
        const Offset(0, size),
      ]) {
        final double hue = RgbWheel.hueAt(p, size);
        expect(hue, greaterThanOrEqualTo(0));
        expect(hue, lessThan(360));
      }
    });

    test('dead-center is the documented 0° fallback', () {
      expect(RgbWheel.hueAt(const Offset(mid, mid), size), 0);
    });
  });

  group('RgbWheel.colorForHue maps hue → vivid HSV color', () {
    test('0° is pure red, 120° green, 240° blue', () {
      expect(
        RgbWheel.colorForHue(0).toARGB32(),
        const Color(0xFFFF0000).toARGB32(),
      );
      expect(
        RgbWheel.colorForHue(120).toARGB32(),
        const Color(0xFF00FF00).toARGB32(),
      );
      expect(
        RgbWheel.colorForHue(240).toARGB32(),
        const Color(0xFF0000FF).toARGB32(),
      );
    });

    test('always full saturation + value (vivid LED color)', () {
      for (double h = 0; h < 360; h += 17) {
        final HSVColor hsv = HSVColor.fromColor(RgbWheel.colorForHue(h));
        expect(hsv.saturation, moreOrLessEquals(1.0, epsilon: 0.01));
        expect(hsv.value, moreOrLessEquals(1.0, epsilon: 0.01));
      }
    });

    test('hue wraps past 360', () {
      expect(
        RgbWheel.colorForHue(360).toARGB32(),
        RgbWheel.colorForHue(0).toARGB32(),
      );
    });
  });
}
