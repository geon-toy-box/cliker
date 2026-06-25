/// Normalizes a raw pointer [pressure] reading into a `[0, 1]` "force" value, or
/// returns `null` when the device reports no usable pressure range.
///
/// Flutter fills [pressureMin]/[pressureMax] with the device's reportable range.
/// Touchscreens and pointers without a force sensor collapse that range
/// (`pressureMin == pressureMax`, typically both `1.0`), which carries no
/// information — so this returns `null` there and callers fall back to a
/// duration-only model. When the range is real, the reading is rescaled to
/// `(pressure - min) / (max - min)` and clamped to `[0, 1]`.
///
/// Kept as a pure, dependency-free top-level function so both the input layer
/// ([Keycap]) and the audio layer can share — and tests can pin — one formula.
double? normalizeForce(
  double pressure,
  double pressureMin,
  double pressureMax,
) {
  final double range = pressureMax - pressureMin;
  if (range <= 0) {
    return null; // No usable pressure range — device has no force sensor.
  }
  final double normalized = (pressure - pressureMin) / range;
  return normalized.clamp(0.0, 1.0);
}
