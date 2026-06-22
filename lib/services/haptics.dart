import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fires device haptics scaled to a switch's feel.
///
/// [click] maps a normalized strength to one of Flutter's [HapticFeedback]
/// impact levels, so a soft linear switch buzzes lighter than a heavy clicky
/// one. Set [enabled] to false to silence all haptics without changing call
/// sites (e.g. when the user turns the setting off).
///
/// Bucket boundaries (strength in [0, 1]):
///
/// | strength      | feedback        |
/// |---------------|-----------------|
/// | `< 0.5`       | `lightImpact`   |
/// | `0.5 – 0.8`   | `mediumImpact`  |
/// | `> 0.8`       | `heavyImpact`   |
class Haptics {
  Haptics({this.enabled = true});

  /// When false, [click] is a no-op and triggers no platform call.
  bool enabled;

  /// Fires the haptic matching [strength]'s bucket. No-op when [enabled] is
  /// false. Boundaries: `< 0.5` light, `[0.5, 0.8]` medium, `> 0.8` heavy.
  Future<void> click(double strength) async {
    if (!enabled) {
      return;
    }
    if (strength < 0.5) {
      await HapticFeedback.lightImpact();
    } else if (strength <= 0.8) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}

/// App-wide haptics service.
///
/// Defaults to enabled; the sound/haptic settings wiring in a later task flips
/// [Haptics.enabled] from the persisted preference.
final Provider<Haptics> hapticsProvider = Provider<Haptics>(
  (Ref ref) => Haptics(),
);
