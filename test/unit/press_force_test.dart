import 'package:cliker/audio/press_force.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForce', () {
    test('returns null when the device reports no pressure range', () {
      // The common touchscreen/web case: Flutter collapses the range to 1..1.
      expect(normalizeForce(1.0, 1.0, 1.0), isNull);
      // Any zero/negative range is unusable.
      expect(normalizeForce(0.5, 0.7, 0.7), isNull);
      expect(normalizeForce(0.5, 1.0, 0.0), isNull);
    });

    test('rescales a real reading into [0, 1] across the reported range', () {
      expect(normalizeForce(0.0, 0.0, 1.0), 0.0);
      expect(normalizeForce(0.5, 0.0, 1.0), 0.5);
      expect(normalizeForce(1.0, 0.0, 1.0), 1.0);
      // A non-zero min is honored (range 0.2..0.8 → midpoint 0.5 maps to 0.5).
      expect(normalizeForce(0.5, 0.2, 0.8), moreOrLessEquals(0.5));
    });

    test('clamps out-of-range readings to [0, 1]', () {
      expect(normalizeForce(-0.3, 0.0, 1.0), 0.0);
      expect(normalizeForce(1.4, 0.0, 1.0), 1.0);
    });
  });
}
