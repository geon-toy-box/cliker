import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// One selectable mechanical-switch profile.
///
/// A [SwitchType] bundles everything the rest of the app needs to present and
/// "feel" a single switch: its identity, display names, the stem color shown on
/// the keycap, a default LED accent, the two sound clips played on press
/// ([downAsset]) and release ([upAsset]), and a normalized [hapticStrength].
///
/// Instances are immutable and compared by [id] alone, so a [SwitchType] can be
/// used safely as a map key or in a [Set]. The canonical instances live in
/// [SwitchCatalog]; this class is not meant to be subclassed or instantiated
/// ad hoc outside the catalog.
@immutable
class SwitchType {
  const SwitchType({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.description,
    required this.stemColor,
    required this.defaultLed,
    required this.downAsset,
    required this.upAsset,
    required this.hapticStrength,
  });

  /// Stable, unique identifier (e.g. `blue`). Used for lookup and equality.
  final String id;

  /// Korean display name (e.g. `청축`).
  final String nameKo;

  /// English display name (e.g. `Blue`).
  final String nameEn;

  /// Short human description of the switch's sound/feel.
  final String description;

  /// Color of the switch stem, drawn on the keycap.
  final Color stemColor;

  /// Default LED accent color for this switch.
  final Color defaultLed;

  /// Asset path for the key-down (press) sound clip.
  final String downAsset;

  /// Asset path for the key-up (release) sound clip.
  final String upAsset;

  /// Haptic intensity in the range (0, 1]; higher is stronger.
  final double hapticStrength;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SwitchType && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SwitchType($id)';
}

/// The fixed catalog of mechanical switches the app ships with.
///
/// [all] is the canonical, ordered list shown in the picker. Color tokens come
/// from [AppColors] so the palette stays single-sourced.
abstract final class SwitchCatalog {
  /// Clicky, bright "딸깍" — the ASMR-defining blue switch.
  static const SwitchType blue = SwitchType(
    id: 'blue',
    nameKo: '청축',
    nameEn: 'Blue',
    description: '또렷한 "딸깍" 클릭음 — 키보드 ASMR의 대표 음색.',
    stemColor: AppColors.switchBlue,
    defaultLed: AppColors.neonCyan,
    downAsset: 'assets/sounds/blue_down.wav',
    upAsset: 'assets/sounds/blue_up.wav',
    hapticStrength: 1,
  );

  /// Tactile bump with a soft "톡" — the brown switch.
  static const SwitchType brown = SwitchType(
    id: 'brown',
    nameKo: '갈축',
    nameEn: 'Brown',
    description: '부드러운 텍타일 범프와 함께 울리는 "톡".',
    stemColor: AppColors.switchBrown,
    defaultLed: AppColors.neonOrange,
    downAsset: 'assets/sounds/brown_down.wav',
    upAsset: 'assets/sounds/brown_up.wav',
    hapticStrength: 0.7,
  );

  /// Smooth, quiet linear "톡" — the red switch.
  static const SwitchType red = SwitchType(
    id: 'red',
    nameKo: '적축',
    nameEn: 'Red',
    description: '매끈하고 조용한 리니어 "톡".',
    stemColor: AppColors.switchRed,
    defaultLed: AppColors.neonMagenta,
    downAsset: 'assets/sounds/red_down.wav',
    upAsset: 'assets/sounds/red_up.wav',
    hapticStrength: 0.45,
  );

  /// Heavy, deep linear — the black switch.
  static const SwitchType black = SwitchType(
    id: 'black',
    nameKo: '흑축',
    nameEn: 'Black',
    description: '묵직하고 깊은 리니어 타건음.',
    stemColor: AppColors.switchBlack,
    defaultLed: AppColors.neonGreen,
    downAsset: 'assets/sounds/black_down.wav',
    upAsset: 'assets/sounds/black_up.wav',
    hapticStrength: 0.6,
  );

  /// All switches in canonical picker order.
  static const List<SwitchType> all = <SwitchType>[blue, brown, red, black];

  /// The switch selected when none has been chosen yet.
  static const SwitchType defaultSwitch = blue;

  /// Returns the switch with [id], or [defaultSwitch] if there is no match.
  static SwitchType byId(String id) {
    for (final SwitchType switchType in all) {
      if (switchType.id == id) {
        return switchType;
      }
    }
    return defaultSwitch;
  }
}
