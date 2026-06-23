import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The actuation family of a mechanical switch.
///
/// - [clicky]: a distinct tactile bump *and* an audible "click" jacket (blue,
///   white).
/// - [tactile]: a felt bump without the click jacket (brown, gray, clear).
/// - [linear]: smooth, bump-free travel (red, black, silents, speed).
enum SwitchKind { clicky, tactile, linear }

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
    required this.kind,
    required this.forceCn,
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

  /// The actuation family (clicky / tactile / linear).
  final SwitchKind kind;

  /// Actuation force in centinewtons (cN), e.g. `50` for a blue switch.
  final int forceCn;

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
    kind: SwitchKind.clicky,
    forceCn: 50,
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
    kind: SwitchKind.tactile,
    forceCn: 45,
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
    kind: SwitchKind.linear,
    forceCn: 45,
    description: '가벼운 리니어, 구름타법.',
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
    kind: SwitchKind.linear,
    forceCn: 60,
    description: '묵직하고 깊은 리니어 타건음.',
    stemColor: AppColors.switchBlack,
    defaultLed: AppColors.neonGreen,
    downAsset: 'assets/sounds/black_down.wav',
    upAsset: 'assets/sounds/black_up.wav',
    hapticStrength: 0.6,
  );

  /// Heavier clicky variant — the white switch.
  static const SwitchType white = SwitchType(
    id: 'white',
    nameKo: '백축',
    nameEn: 'White',
    kind: SwitchKind.clicky,
    forceCn: 55,
    description: '청축보다 무거운 또렷한 클릭.',
    stemColor: AppColors.switchWhite,
    defaultLed: AppColors.neonCyan,
    downAsset: 'assets/sounds/white_down.wav',
    upAsset: 'assets/sounds/white_up.wav',
    hapticStrength: 0.85,
  );

  /// High-force tactile — the gray switch.
  static const SwitchType gray = SwitchType(
    id: 'gray',
    nameKo: '회축',
    nameEn: 'Gray',
    kind: SwitchKind.tactile,
    forceCn: 80,
    description: '강한 텍타일 범프의 고압 스위치.',
    stemColor: AppColors.switchGray,
    defaultLed: AppColors.neonYellow,
    downAsset: 'assets/sounds/gray_down.wav',
    upAsset: 'assets/sounds/gray_up.wav',
    hapticStrength: 0.95,
  );

  /// Stiffer tactile — the clear switch.
  static const SwitchType clear = SwitchType(
    id: 'clear',
    nameKo: '클리어축',
    nameEn: 'Clear',
    kind: SwitchKind.tactile,
    forceCn: 65,
    description: '갈축보다 또렷한 텍타일 범프.',
    stemColor: AppColors.switchClear,
    defaultLed: AppColors.neonPurple,
    downAsset: 'assets/sounds/clear_down.wav',
    upAsset: 'assets/sounds/clear_up.wav',
    hapticStrength: 0.8,
  );

  /// Dampened linear — the silent red switch.
  static const SwitchType silentRed = SwitchType(
    id: 'silentRed',
    nameKo: '저소음 적축',
    nameEn: 'Silent Red',
    kind: SwitchKind.linear,
    forceCn: 45,
    description: '댐퍼로 조용한 가벼운 리니어.',
    stemColor: AppColors.switchSilentRed,
    defaultLed: AppColors.neonMagenta,
    downAsset: 'assets/sounds/silentRed_down.wav',
    upAsset: 'assets/sounds/silentRed_up.wav',
    hapticStrength: 0.4,
  );

  /// Dampened heavy linear — the silent black switch.
  static const SwitchType silentBlack = SwitchType(
    id: 'silentBlack',
    nameKo: '저소음 흑축',
    nameEn: 'Silent Black',
    kind: SwitchKind.linear,
    forceCn: 60,
    description: '댐퍼로 조용한 묵직한 리니어.',
    stemColor: AppColors.switchSilentBlack,
    defaultLed: AppColors.neonGreen,
    downAsset: 'assets/sounds/silentBlack_down.wav',
    upAsset: 'assets/sounds/silentBlack_up.wav',
    hapticStrength: 0.55,
  );

  /// Short-travel linear — the speed silver switch.
  static const SwitchType speedSilver = SwitchType(
    id: 'speedSilver',
    nameKo: '스피드 은축',
    nameEn: 'Speed Silver',
    kind: SwitchKind.linear,
    forceCn: 45,
    description: '1.2mm 짧은 행정의 빠른 리니어.',
    stemColor: AppColors.switchSpeedSilver,
    defaultLed: AppColors.neonCyan,
    downAsset: 'assets/sounds/speedSilver_down.wav',
    upAsset: 'assets/sounds/speedSilver_up.wav',
    hapticStrength: 0.5,
  );

  /// High-force linear — the dark gray switch.
  static const SwitchType darkGray = SwitchType(
    id: 'darkGray',
    nameKo: '진회축',
    nameEn: 'Dark Gray',
    kind: SwitchKind.linear,
    forceCn: 80,
    description: '가장 묵직한 고압 리니어.',
    stemColor: AppColors.switchDarkGray,
    defaultLed: AppColors.neonYellow,
    downAsset: 'assets/sounds/darkGray_down.wav',
    upAsset: 'assets/sounds/darkGray_up.wav',
    hapticStrength: 0.9,
  );

  /// All switches in canonical picker order.
  static const List<SwitchType> all = <SwitchType>[
    blue,
    brown,
    red,
    black,
    white,
    gray,
    clear,
    silentRed,
    silentBlack,
    speedSilver,
    darkGray,
  ];

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
