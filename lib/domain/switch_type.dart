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
/// "feel" a single switch: its identity, display names, the picker copy
/// ([description] = 느낌, [recommendedFor] = 추천 용도, [loudness] = 소리세기),
/// the stem color shown on the keycap, a default LED accent, the two sound clips
/// played on press ([downAsset]) and release ([upAsset]), and a normalized
/// [hapticStrength].
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
    required this.recommendedFor,
    required this.loudness,
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

  /// One-line "느낌" — how the switch feels to type on (the tactile/typing
  /// character), shown in the picker.
  final String description;

  /// One-line "추천 용도" — who/what this switch is recommended for, shown in
  /// the picker. Never empty.
  final String recommendedFor;

  /// Subjective loudness on a 1–5 scale (1 = very quiet, 5 = very loud), used
  /// to render the sound-level indicator in the picker.
  final int loudness;

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
    description: '또렷한 딸깍 클릭, 강한 피드백',
    recommendedFor: '타이핑·손맛·ASMR',
    loudness: 5,
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
    description: '부드러운 구분감 범프',
    recommendedFor: '코딩·문서·입문',
    loudness: 3,
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
    description: '걸림 없이 부드럽게 쭉',
    recommendedFor: '게임·사무',
    loudness: 2,
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
    description: '묵직·탄탄, 강한 반발',
    recommendedFor: '오타 방지·강한 입력',
    loudness: 2,
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
    description: '청축 손맛에 소음은 한 톤 낮게',
    recommendedFor: '손맛 + 소음↓',
    loudness: 4,
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
    description: '고압 텍타일, 강한 구분감',
    recommendedFor: '묵직한 택타일 선호',
    loudness: 3,
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
    description: '갈축보다 진한 범프',
    recommendedFor: '또렷한 구분감',
    loudness: 3,
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
    description: '댐퍼로 가장 조용한 리니어',
    recommendedFor: '사무실·공유공간',
    loudness: 1,
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
    description: '묵직하지만 조용하게',
    recommendedFor: '야간·정숙 환경',
    loudness: 1,
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
    description: '1.2mm 초고속 액추에이션',
    recommendedFor: 'FPS·빠른 반응',
    loudness: 2,
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
    description: '고압 리니어, 깊고 무겁게',
    recommendedFor: '강한 입력감',
    loudness: 2,
    stemColor: AppColors.switchDarkGray,
    defaultLed: AppColors.neonYellow,
    downAsset: 'assets/sounds/darkGray_down.wav',
    upAsset: 'assets/sounds/darkGray_up.wav',
    hapticStrength: 0.9,
  );

  /// Smooth, "쫀득" full-body linear — the yellow switch.
  static const SwitchType yellow = SwitchType(
    id: 'yellow',
    nameKo: '황축',
    nameEn: 'Yellow',
    kind: SwitchKind.linear,
    forceCn: 50,
    description: '적축보다 쫀득·부드러운 리니어',
    recommendedFor: '커스텀 키감·부드러움',
    loudness: 2,
    stemColor: AppColors.switchYellow,
    defaultLed: AppColors.neonYellow,
    downAsset: 'assets/sounds/yellow_down.wav',
    upAsset: 'assets/sounds/yellow_up.wav',
    hapticStrength: 0.5,
  );

  /// Contactless Hall-effect / rapid-trigger linear — the magnetic switch. The
  /// switch is analog in hardware, but for the app's [SwitchKind] taxonomy it is
  /// modeled as a smooth [SwitchKind.linear]; "무접점" lives in [description].
  static const SwitchType magnetic = SwitchType(
    id: 'magnetic',
    nameKo: '자석축',
    nameEn: 'Magnetic',
    kind: SwitchKind.linear,
    forceCn: 40,
    description: '무접점 홀이펙트·래피드 트리거',
    recommendedFor: 'e스포츠·정밀 제어',
    loudness: 1,
    stemColor: AppColors.switchMagnetic,
    defaultLed: AppColors.neonCyan,
    downAsset: 'assets/sounds/magnetic_down.wav',
    upAsset: 'assets/sounds/magnetic_up.wav',
    hapticStrength: 0.45,
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
    yellow,
    magnetic,
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
