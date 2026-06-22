import 'package:cliker/util/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('thousands', () {
    test('leaves 0–999 unchanged', () {
      expect(thousands(0), '0');
      expect(thousands(7), '7');
      expect(thousands(42), '42');
      expect(thousands(999), '999');
    });

    test('groups four-, five-, and six-digit numbers', () {
      expect(thousands(1000), '1,000');
      expect(thousands(1234), '1,234');
      expect(thousands(12345), '12,345');
      expect(thousands(123456), '123,456');
    });

    test('groups numbers spanning multiple commas', () {
      expect(thousands(1000000), '1,000,000');
      expect(thousands(1234567), '1,234,567');
    });

    test('handles negatives by prefixing the sign', () {
      expect(thousands(-5), '-5');
      expect(thousands(-1234), '-1,234');
    });
  });
}
