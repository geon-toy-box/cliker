import 'package:cliker/app.dart';
import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/rgb_wheel.dart';
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

      // Sheet root, both toggles, the LED color wheel, all four mode chips.
      expect(find.byKey(SettingsSheet.sheetKey), findsOneWidget);
      expect(find.byKey(SettingsSheet.soundToggleKey), findsOneWidget);
      expect(find.byKey(SettingsSheet.hapticToggleKey), findsOneWidget);
      // The six-swatch palette is replaced by the RGB wheel inside the sheet.
      // (The home screen also has a wheel, so scope the match to the sheet.)
      expect(
        find.descendant(
          of: find.byKey(SettingsSheet.sheetKey),
          matching: find.byKey(RgbWheel.wheelKey),
        ),
        findsOneWidget,
      );
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
        // Pin the classic single-clip sound path so the played-count assertion
        // (down + up = 2) is about haptic gating, not the dynamic decomposition.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'settings.dynamicClickEnabled': false,
        });
        final SharedPreferences classicPrefs =
            await SharedPreferences.getInstance();
        final ProviderContainer container = await pumpApp(
          tester,
          prefs: classicPrefs,
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

  group('AC3: RGB wheel updates provider + keycap glow + persists', () {
    testWidgets('picking a hue on the home wheel recolors the glow + persists', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );

      // Defaults to neonCyan; the resting glow carries the cyan hue (its alpha
      // differs from the swatch, so compare only the RGB channels).
      final int cyan = AppColors.neonCyan.toARGB32();
      expect(container.read(settingsProvider).ledColorArgb, cyan);
      expect(
        keycapGlowColor(tester).toARGB32() & 0x00FFFFFF,
        cyan & 0x00FFFFFF,
      );

      // Tap the bottom-edge of the wheel → hue ≈ 180° (cyan/teal region). The
      // exact color comes from RgbWheel.hueAt, so derive the expected value the
      // same way the widget does and compare against it.
      final Rect wheel = tester.getRect(find.byKey(RgbWheel.wheelKey));
      final Offset tapPoint = Offset(wheel.center.dx, wheel.bottom - 2);
      final double expectedHue = RgbWheel.hueAt(
        tapPoint - wheel.topLeft,
        wheel.width,
      );
      final int expectedArgb = RgbWheel.colorForHue(expectedHue).toARGB32();

      await tester.tapAt(tapPoint);
      await tester.pump();

      // Provider updated to exactly the wheel's emitted color.
      expect(container.read(settingsProvider).ledColorArgb, expectedArgb);
      // And it is no longer the default cyan.
      expect(container.read(settingsProvider).ledColorArgb, isNot(cyan));

      // The keycap glow follows the new color (RGB channels match).
      expect(
        keycapGlowColor(tester).toARGB32() & 0x00FFFFFF,
        expectedArgb & 0x00FFFFFF,
      );

      // Persisted: a fresh container over the same prefs keeps the pick.
      final SharedPreferences freshPrefs =
          await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).ledColorArgb, expectedArgb);
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
      // The sheet now scrolls; the LED-mode chips sit below the fold, so bring
      // the target chip into view before tapping it.
      final Finder rgbChip = find.byKey(
        SettingsSheet.modeChipKey(LedMode.rgbCycle),
      );
      await tester.ensureVisible(rgbChip);
      await tester.pump();
      await tester.tap(rgbChip);
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

  group('dynamic-click controls', () {
    testWidgets('sheet shows the dynamic-click toggle + 강도 slider', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, prefs: prefs, player: player);
      await openSheet(tester);

      expect(find.byKey(SettingsSheet.dynamicClickToggleKey), findsOneWidget);
      expect(
        find.byKey(SettingsSheet.dynamicIntensitySliderKey),
        findsOneWidget,
      );
    });

    testWidgets(
      'toggling dynamic click OFF persists and disables the 강도 slider',
      (WidgetTester tester) async {
        final ProviderContainer container = await pumpApp(
          tester,
          prefs: prefs,
          player: player,
        );
        expect(container.read(settingsProvider).dynamicClickEnabled, isTrue);

        await openSheet(tester);

        // On by default → the slider is interactive.
        final Slider before = tester.widget<Slider>(
          find.byKey(SettingsSheet.dynamicIntensitySliderKey),
        );
        expect(before.onChanged, isNotNull);

        await tester.tap(find.byKey(SettingsSheet.dynamicClickToggleKey));
        await tester.pumpAndSettle();

        // Provider flips and the slider goes inert (onChanged == null).
        expect(container.read(settingsProvider).dynamicClickEnabled, isFalse);
        final Slider after = tester.widget<Slider>(
          find.byKey(SettingsSheet.dynamicIntensitySliderKey),
        );
        expect(after.onChanged, isNull);

        // Persisted across a fresh container over the same prefs.
        final SharedPreferences freshPrefs =
            await SharedPreferences.getInstance();
        final ProviderContainer second = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
        );
        addTearDown(second.dispose);
        expect(second.read(settingsProvider).dynamicClickEnabled, isFalse);
      },
    );

    testWidgets('dragging the 강도 slider updates and persists the intensity', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );
      expect(
        container.read(settingsProvider).dynamicClickIntensity,
        SettingsNotifier.defaultDynamicClickIntensity,
      );

      await openSheet(tester);

      // Drag the slider thumb to the right — intensity must increase.
      await tester.drag(
        find.byKey(SettingsSheet.dynamicIntensitySliderKey),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();

      final double updated = container
          .read(settingsProvider)
          .dynamicClickIntensity;
      expect(
        updated,
        greaterThan(SettingsNotifier.defaultDynamicClickIntensity),
      );

      // Persisted across a fresh container.
      final SharedPreferences freshPrefs =
          await SharedPreferences.getInstance();
      final ProviderContainer second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
      );
      addTearDown(second.dispose);
      expect(
        second.read(settingsProvider).dynamicClickIntensity,
        moreOrLessEquals(updated),
      );
    });
  });
}
