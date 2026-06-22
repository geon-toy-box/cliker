/// Formats [value] with thousands separators, e.g. `1234` → `1,234`.
///
/// Self-contained (no `intl` dependency): groups the digits of the absolute
/// value in threes from the right and re-attaches a leading `-` for negatives.
/// `0`–`999` are returned unchanged. Used by the stats panel so large counts
/// stay legible.
String thousands(int value) {
  final bool negative = value < 0;
  final String digits = value.abs().toString();

  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    // Insert a comma before every group of three, except at the very start.
    final int remaining = digits.length - i;
    if (i != 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return negative ? '-$buffer' : buffer.toString();
}
