import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a [ProviderContainer] wired to a fresh mock-prefs instance seeded
/// with [initial]. A fresh container with the *same* backing prefs simulates an
/// app restart: in-memory provider state is gone, persisted values remain.
Future<ProviderContainer> containerWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier defaults from empty prefs (AC1)', () {
    test('returns the spec defaults when prefs are empty', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );

      final Settings settings = container.read(settingsProvider);

      expect(settings.selectedSwitchId, SwitchCatalog.defaultSwitch.id);
      expect(settings.selectedSwitchId, 'blue');
      expect(settings.soundEnabled, isTrue);
      expect(settings.hapticEnabled, isTrue);
      expect(settings.ledMode, LedMode.ripple);
      expect(settings.ledColorArgb, AppColors.accentDefault.toARGB32());
    });
  });

  group('Setters persist across a fresh container (AC2)', () {
    test('selectSwitch persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      first.read(settingsProvider.notifier).selectSwitch('red');
      expect(first.read(settingsProvider).selectedSwitchId, 'red');

      // Fresh container, same underlying mock prefs -> value must survive.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).selectedSwitchId, 'red');
    });

    test('setSound persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      first.read(settingsProvider.notifier).setSound(enabled: false);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).soundEnabled, isFalse);
    });

    test('setHaptic persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      first.read(settingsProvider.notifier).setHaptic(enabled: false);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).hapticEnabled, isFalse);
    });

    test('setLedMode persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      first.read(settingsProvider.notifier).setLedMode(LedMode.rgbCycle);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).ledMode, LedMode.rgbCycle);
    });

    test('setLedColor persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      final int magenta = AppColors.neonMagenta.toARGB32();
      first.read(settingsProvider.notifier).setLedColor(magenta);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).ledColorArgb, magenta);
    });
  });

  group('Settings value semantics', () {
    test('copyWith changes only named fields', () {
      const Settings base = Settings(
        selectedSwitchId: 'blue',
        soundEnabled: true,
        hapticEnabled: true,
        ledMode: LedMode.ripple,
        ledColorArgb: 0xFF00E5FF,
      );
      final Settings changed = base.copyWith(soundEnabled: false);

      expect(changed.soundEnabled, isFalse);
      expect(changed.selectedSwitchId, base.selectedSwitchId);
      expect(changed.hapticEnabled, base.hapticEnabled);
      expect(changed.ledMode, base.ledMode);
      expect(changed.ledColorArgb, base.ledColorArgb);
    });

    test('equality and hashCode are value-based', () {
      const Settings a = Settings(
        selectedSwitchId: 'blue',
        soundEnabled: true,
        hapticEnabled: true,
        ledMode: LedMode.ripple,
        ledColorArgb: 0xFF00E5FF,
      );
      const Settings b = Settings(
        selectedSwitchId: 'blue',
        soundEnabled: true,
        hapticEnabled: true,
        ledMode: LedMode.ripple,
        ledColorArgb: 0xFF00E5FF,
      );
      const Settings c = Settings(
        selectedSwitchId: 'red',
        soundEnabled: true,
        hapticEnabled: true,
        ledMode: LedMode.ripple,
        ledColorArgb: 0xFF00E5FF,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
