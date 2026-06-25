import 'dart:async';

import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the keycap LED reacts to clicks.
///
/// - [ripple]: a colored ring expands from the press point.
/// - [solid]: a steady fill in [Settings.ledColorArgb].
/// - [rgbCycle]: the color sweeps through the neon palette over time.
/// - [reactive]: brightness/intensity tracks click cadence.
///
/// Only the selected value is persisted here; the visual implementation lives
/// in later UI tasks.
enum LedMode { ripple, solid, rgbCycle, reactive }

/// Immutable user settings: the chosen switch, sound/haptic toggles, and the
/// keycap LED mode + color.
///
/// Compared by value so Riverpod can skip rebuilds when nothing changed.
@immutable
class Settings {
  const Settings({
    required this.selectedSwitchId,
    required this.soundEnabled,
    required this.hapticEnabled,
    required this.ledMode,
    required this.ledColorArgb,
    required this.dynamicClickEnabled,
    required this.dynamicClickIntensity,
  });

  /// Id of the selected [SwitchType] (see [SwitchCatalog]).
  final String selectedSwitchId;

  /// Whether press/release click sounds play.
  final bool soundEnabled;

  /// Whether haptic feedback fires on click.
  final bool hapticEnabled;

  /// The active keycap LED animation mode.
  final LedMode ledMode;

  /// LED color as a packed 32-bit ARGB integer.
  final int ledColorArgb;

  /// Whether the dynamic-click engine is on: a press decomposes into the
  /// drawn-out onset→click→bottom "따~알~깍" (vs. a single fixed "딸깍" when off).
  final bool dynamicClickEnabled;

  /// How drawn-out the dynamic decomposition is, in `[0, 1]` (the "강도" slider).
  /// Higher spreads the onset/click/bottom further apart in time. Only meaningful
  /// when [dynamicClickEnabled] is true.
  final double dynamicClickIntensity;

  Settings copyWith({
    String? selectedSwitchId,
    bool? soundEnabled,
    bool? hapticEnabled,
    LedMode? ledMode,
    int? ledColorArgb,
    bool? dynamicClickEnabled,
    double? dynamicClickIntensity,
  }) {
    return Settings(
      selectedSwitchId: selectedSwitchId ?? this.selectedSwitchId,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      ledMode: ledMode ?? this.ledMode,
      ledColorArgb: ledColorArgb ?? this.ledColorArgb,
      dynamicClickEnabled: dynamicClickEnabled ?? this.dynamicClickEnabled,
      dynamicClickIntensity:
          dynamicClickIntensity ?? this.dynamicClickIntensity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Settings &&
          other.selectedSwitchId == selectedSwitchId &&
          other.soundEnabled == soundEnabled &&
          other.hapticEnabled == hapticEnabled &&
          other.ledMode == ledMode &&
          other.ledColorArgb == ledColorArgb &&
          other.dynamicClickEnabled == dynamicClickEnabled &&
          other.dynamicClickIntensity == dynamicClickIntensity);

  @override
  int get hashCode => Object.hash(
    selectedSwitchId,
    soundEnabled,
    hapticEnabled,
    ledMode,
    ledColorArgb,
    dynamicClickEnabled,
    dynamicClickIntensity,
  );

  @override
  String toString() =>
      'Settings(selectedSwitchId: $selectedSwitchId, soundEnabled: '
      '$soundEnabled, hapticEnabled: $hapticEnabled, ledMode: $ledMode, '
      'ledColorArgb: $ledColorArgb, dynamicClickEnabled: $dynamicClickEnabled, '
      'dynamicClickIntensity: $dynamicClickIntensity)';
}

/// Reads [Settings] from [SharedPreferences] on build and writes each change
/// straight back, so settings survive an app restart.
class SettingsNotifier extends Notifier<Settings> {
  static const String _keySelectedSwitchId = 'settings.selectedSwitchId';
  static const String _keySoundEnabled = 'settings.soundEnabled';
  static const String _keyHapticEnabled = 'settings.hapticEnabled';
  static const String _keyLedMode = 'settings.ledMode';
  static const String _keyLedColorArgb = 'settings.ledColorArgb';
  static const String _keyDynamicClickEnabled = 'settings.dynamicClickEnabled';
  static const String _keyDynamicClickIntensity =
      'settings.dynamicClickIntensity';

  /// Default dynamic-click decomposition amount when nothing is persisted yet.
  static const double defaultDynamicClickIntensity = 0.5;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Settings build() {
    final SharedPreferences prefs = _prefs;
    return Settings(
      selectedSwitchId:
          prefs.getString(_keySelectedSwitchId) ??
          SwitchCatalog.defaultSwitch.id,
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
      hapticEnabled: prefs.getBool(_keyHapticEnabled) ?? true,
      ledMode: _ledModeFromName(prefs.getString(_keyLedMode)),
      ledColorArgb:
          prefs.getInt(_keyLedColorArgb) ?? AppColors.accentDefault.toARGB32(),
      dynamicClickEnabled: prefs.getBool(_keyDynamicClickEnabled) ?? true,
      dynamicClickIntensity:
          (prefs.getDouble(_keyDynamicClickIntensity) ??
                  defaultDynamicClickIntensity)
              .clamp(0.0, 1.0),
    );
  }

  /// Selects the switch identified by [id] and persists it.
  void selectSwitch(String id) {
    state = state.copyWith(selectedSwitchId: id);
    unawaited(_prefs.setString(_keySelectedSwitchId, id));
  }

  /// Toggles click sounds and persists the choice.
  void setSound({required bool enabled}) {
    state = state.copyWith(soundEnabled: enabled);
    unawaited(_prefs.setBool(_keySoundEnabled, enabled));
  }

  /// Toggles haptic feedback and persists the choice.
  void setHaptic({required bool enabled}) {
    state = state.copyWith(hapticEnabled: enabled);
    unawaited(_prefs.setBool(_keyHapticEnabled, enabled));
  }

  /// Sets the LED [mode] and persists it.
  void setLedMode(LedMode mode) {
    state = state.copyWith(ledMode: mode);
    unawaited(_prefs.setString(_keyLedMode, mode.name));
  }

  /// Sets the LED color (packed 32-bit ARGB) and persists it.
  void setLedColor(int argb) {
    state = state.copyWith(ledColorArgb: argb);
    unawaited(_prefs.setInt(_keyLedColorArgb, argb));
  }

  /// Toggles the dynamic-click engine ("따~알~깍" vs. fixed "딸깍") and persists it.
  void setDynamicClick({required bool enabled}) {
    state = state.copyWith(dynamicClickEnabled: enabled);
    unawaited(_prefs.setBool(_keyDynamicClickEnabled, enabled));
  }

  /// Sets the dynamic-click decomposition amount (clamped to `[0, 1]`) and
  /// persists it.
  void setDynamicClickIntensity(double intensity) {
    final double clamped = intensity.clamp(0.0, 1.0);
    state = state.copyWith(dynamicClickIntensity: clamped);
    unawaited(_prefs.setDouble(_keyDynamicClickIntensity, clamped));
  }

  /// Maps a stored mode name back to a [LedMode], defaulting to [LedMode.ripple]
  /// when absent or unrecognized (e.g. an older/newer build wrote a name we
  /// don't know).
  static LedMode _ledModeFromName(String? name) {
    if (name == null) {
      return LedMode.ripple;
    }
    for (final LedMode mode in LedMode.values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return LedMode.ripple;
  }
}

/// App-wide settings state.
final NotifierProvider<SettingsNotifier, Settings> settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
