import 'package:cliker/app.dart';
import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every backend call so a test can assert exactly which sounds the
/// player asked to play, without touching platform channels. Mirrors the fake
/// used by the M1 smoke test so the player behaves identically.
class FakeBackend implements SoundBackend {
  final List<String> loaded = <String>[];
  final List<({int soundId, double volume})> played =
      <({int soundId, double volume})>[];
  final Map<String, int> idByAsset = <String, int>{};
  int _next = 0;

  @override
  Future<int> load(String asset) async {
    loaded.add(asset);
    return idByAsset.putIfAbsent(asset, () => _next++);
  }

  @override
  Future<void> play(int soundId, {double volume = 1.0}) async {
    played.add((soundId: soundId, volume: volume));
  }

  @override
  Future<void> dispose() async {}
}

/// Builds the app under a [ProviderScope] with [SharedPreferences] and a
/// [ClickSoundPlayer] (on a fake backend) overridden, so the screen renders
/// with no platform dependencies. Returns the [ProviderContainer] so tests can
/// read provider state directly.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required ClickSoundPlayer player,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clickSoundPlayerProvider.overrideWithValue(player),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const ClikerApp()),
  );
  return container;
}

/// Reads the live LED glow color off the keycap's inner-cap [BoxShadow].
Color keycapGlowColor(WidgetTester tester) {
  final Container cap = tester.widget<Container>(
    find.byKey(Keycap.innerCapKey),
  );
  final BoxDecoration decoration = cap.decoration! as BoxDecoration;
  return decoration.boxShadow!.first.color;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeBackend backend;
  late ClickSoundPlayer player;

  /// Haptic-vibrate args captured off the platform channel.
  late List<String?> vibrateArgs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    backend = FakeBackend();
    player = ClickSoundPlayer(backend);
    await player.init();

    vibrateArgs = <String?>[];
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrateArgs.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Taps the settings button and settles the bottom-sheet open animation.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(HomeScreen.settingsButtonKey));
    await tester.pumpAndSettle();
  }

  /// Presses the keycap down only (no release), so a test can read the
  /// down-side side effects in isolation.
  Future<TestGesture> pressKeycapDown(WidgetTester tester) async {
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Keycap.innerCapKey)),
    );
    await tester.pump();
    return gesture;
  }

  group('AC1: settings entry point + sheet contents', () {
    testWidgets('settings button opens the sheet with every control', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, prefs: prefs, player: player);

      // Sheet is not present until the button is tapped.
      expect(find.byKey(SettingsSheet.sheetKey), findsNothing);

      await openSheet(tester);

      // Sheet root, both toggles, all six swatches, all four mode chips.
      expect(find.byKey(SettingsSheet.sheetKey), findsOneWidget);
      expect(find.byKey(SettingsSheet.soundToggleKey), findsOneWidget);
      expect(find.byKey(SettingsSheet.hapticToggleKey), findsOneWidget);
      for (final Color color in AppColors.ledPalette) {
        expect(
          find.byKey(SettingsSheet.swatchKey(color.toARGB32())),
          findsOneWidget,
        );
      }
      for (final LedMode mode in LedMode.values) {
        expect(find.byKey(SettingsSheet.modeChipKey(mode)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('AC2: sound/haptic toggles gate the keycap press', () {
    testWidgets(
      'toggling sound OFF sets soundEnabled=false and suppresses playback',
      (WidgetTester tester) async {
        final ProviderContainer container = await pumpApp(
          tester,
          prefs: prefs,
          player: player,
        );
        expect(container.read(settingsProvider).soundEnabled, isTrue);

        await openSheet(tester);
        await tester.tap(find.byKey(SettingsSheet.soundToggleKey));
        await tester.pumpAndSettle();

        // Provider reflects the toggle immediately.
        expect(container.read(settingsProvider).soundEnabled, isFalse);

        // Close the sheet and press the keycap: no sound should play.
        await tester.tapAt(const Offset(10, 10)); // tap the scrim to dismiss
        await tester.pumpAndSettle();

        final TestGesture gesture = await pressKeycapDown(tester);
        await gesture.up();
        await tester.pump();

        expect(backend.played, isEmpty);
        // Haptic still fired (only sound was disabled).
        expect(vibrateArgs, hasLength(1));
      },
    );

    testWidgets(
      'toggling haptic OFF sets hapticEnabled=false and suppresses vibration',
      (WidgetTester tester) async {
        final ProviderContainer container = await pumpApp(
          tester,
          prefs: prefs,
          player: player,
        );
        expect(container.read(settingsProvider).hapticEnabled, isTrue);

        await openSheet(tester);
        await tester.tap(find.byKey(SettingsSheet.hapticToggleKey));
        await tester.pumpAndSettle();

        expect(container.read(settingsProvider).hapticEnabled, isFalse);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        final TestGesture gesture = await pressKeycapDown(tester);
        await gesture.up();
        await tester.pump();

        // No haptic fired, but the sound (down + up) still played.
        expect(vibrateArgs, isEmpty);
        expect(backend.played, hasLength(2));
      },
    );
  });

  group('AC3: color swatch updates provider + keycap glow + persists', () {
    testWidgets('selecting neonMagenta recolors the glow and persists', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );

      // Defaults to neonCyan.
      final int cyan = AppColors.neonCyan.toARGB32();
      final int magenta = AppColors.neonMagenta.toARGB32();
      expect(container.read(settingsProvider).ledColorArgb, cyan);
      // The resting glow carries the cyan hue (alpha differs from the swatch).
      expect(
        keycapGlowColor(tester).toARGB32() & 0x00FFFFFF,
        cyan & 0x00FFFFFF,
      );

      await openSheet(tester);
      await tester.tap(find.byKey(SettingsSheet.swatchKey(magenta)));
      await tester.pumpAndSettle();

      // Provider updated, then dismiss the sheet and re-check the glow.
      expect(container.read(settingsProvider).ledColorArgb, magenta);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(
        keycapGlowColor(tester).toARGB32() & 0x00FFFFFF,
        magenta & 0x00FFFFFF,
      );

      // Persisted: a fresh container over the same prefs keeps magenta.
      final SharedPreferences freshPrefs =
          await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).ledColorArgb, magenta);
    });
  });

  group('persistence: mode selection survives a fresh container', () {
    testWidgets('selecting rgbCycle persists', (WidgetTester tester) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );
      expect(container.read(settingsProvider).ledMode, LedMode.ripple);

      await openSheet(tester);
      await tester.tap(find.byKey(SettingsSheet.modeChipKey(LedMode.rgbCycle)));
      // Cannot pumpAndSettle here: rgbCycle starts a perpetual hue animation in
      // the keycap behind the sheet, so the tree never reaches a steady state.
      // A couple of fixed frames is enough to apply the chip selection.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(settingsProvider).ledMode, LedMode.rgbCycle);

      final SharedPreferences freshPrefs =
          await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).ledMode, LedMode.rgbCycle);
    });
  });
}
