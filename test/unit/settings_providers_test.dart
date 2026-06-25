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
      // Dynamic click ships on by default, at the mid-spread intensity.
      expect(settings.dynamicClickEnabled, isTrue);
      expect(
        settings.dynamicClickIntensity,
        SettingsNotifier.defaultDynamicClickIntensity,
      );
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

    test('setDynamicClick persists', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      expect(first.read(settingsProvider).dynamicClickEnabled, isTrue);
      first.read(settingsProvider.notifier).setDynamicClick(enabled: false);
      expect(first.read(settingsProvider).dynamicClickEnabled, isFalse);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).dynamicClickEnabled, isFalse);
    });

    test('setDynamicClickIntensity persists and clamps to [0, 1]', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      // Out-of-range input is clamped before it is stored.
      first.read(settingsProvider.notifier).setDynamicClickIntensity(1.8);
      expect(first.read(settingsProvider).dynamicClickIntensity, 1.0);
      first.read(settingsProvider.notifier).setDynamicClickIntensity(0.25);
      expect(first.read(settingsProvider).dynamicClickIntensity, 0.25);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);

      expect(second.read(settingsProvider).dynamicClickIntensity, 0.25);
    });
  });

  group('Settings value semantics', () {
    const Settings base = Settings(
      selectedSwitchId: 'blue',
      soundEnabled: true,
      hapticEnabled: true,
      ledMode: LedMode.ripple,
      ledColorArgb: 0xFF00E5FF,
      dynamicClickEnabled: true,
      dynamicClickIntensity: 0.5,
    );

    test('copyWith changes only named fields', () {
      final Settings changed = base.copyWith(soundEnabled: false);

      expect(changed.soundEnabled, isFalse);
      expect(changed.selectedSwitchId, base.selectedSwitchId);
      expect(changed.hapticEnabled, base.hapticEnabled);
      expect(changed.ledMode, base.ledMode);
      expect(changed.ledColorArgb, base.ledColorArgb);
      // Untouched dynamic fields pass through unchanged.
      expect(changed.dynamicClickEnabled, base.dynamicClickEnabled);
      expect(changed.dynamicClickIntensity, base.dynamicClickIntensity);
    });

    test('copyWith updates the dynamic-click fields', () {
      final Settings changed = base.copyWith(
        dynamicClickEnabled: false,
        dynamicClickIntensity: 0.9,
      );
      expect(changed.dynamicClickEnabled, isFalse);
      expect(changed.dynamicClickIntensity, 0.9);
      // Other fields untouched.
      expect(changed.soundEnabled, base.soundEnabled);
    });

    test('equality and hashCode are value-based', () {
      final Settings a = base.copyWith();
      final Settings b = base.copyWith();
      final Settings c = base.copyWith(selectedSwitchId: 'red');
      // Differing only in a dynamic field still breaks equality.
      final Settings d = base.copyWith(dynamicClickIntensity: 0.7);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });
  });
}
