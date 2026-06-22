/// Spacing scale (logical pixels) for consistent layout rhythm.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner-radius scale (logical pixels). `pill` is an effectively-infinite
/// radius for fully rounded ("pill") shapes.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}
