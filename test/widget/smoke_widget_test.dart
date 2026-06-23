import 'package:cliker/app.dart';
import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every backend call so a test can assert exactly which sounds the
/// player asked to load and play, without touching platform channels. Mirrors
/// the fake used by the unit tests so the player behaves identically here.
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

/// Builds the app under a [ProviderScope] with [SharedPreferences],
/// [ClickSoundPlayer] (on [backend]), all overridden so the screen renders with
/// no platform dependencies. Returns the [ProviderContainer] so tests can read
/// provider state directly.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeBackend backend;
  late ClickSoundPlayer player;

  /// Haptic-vibrate args captured off the platform channel (AC4).
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

  /// Performs one full keycap press (down + up) and settles the animations.
  Future<void> tapKeycap(WidgetTester tester) async {
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(Keycap.innerCapKey)),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // Let press + ripple animations finish so they don't bleed into the next.
    await tester.pump(Keycap.rippleDuration + const Duration(milliseconds: 1));
    await tester.pump();
  }

  group('HomeScreen layout (AC3, AC6)', () {
    testWidgets(
      'cold start shows the keycap, exactly two stats, and eleven switch chips',
      (WidgetTester tester) async {
        await pumpApp(tester, prefs: prefs, player: player);

        // Center keycap with the default switch (blue) label.
        expect(find.byType(Keycap), findsOneWidget);
        expect(find.text(SwitchCatalog.blue.nameEn), findsOneWidget);

        // Stats readout: exactly the two spec'd values, starting at 0.
        expect(find.byKey(HomeScreen.totalStatKey), findsOneWidget);
        expect(find.byKey(HomeScreen.rpmStatKey), findsOneWidget);
        expect(find.byKey(const Key('stat-session')), findsNothing);
        expect(find.byKey(const Key('stat-cpm')), findsNothing);
        expect(find.byKey(const Key('stat-best')), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data,
          '0',
        );

        // One chip per catalog switch — all eleven, found via their keys
        // (chips off-screen in the horizontal list are still in the tree).
        expect(SwitchCatalog.all, hasLength(11));
        for (final SwitchType s in SwitchCatalog.all) {
          expect(
            find.byKey(HomeScreen.switchChipKey(s.id)),
            findsOneWidget,
            reason: 'chip for ${s.id}',
          );
        }

        // The selector is horizontally scrollable.
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Scrollable && w.axisDirection == AxisDirection.right,
          ),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Counter increment (AC3)', () {
    testWidgets('three taps drive total to 3', (WidgetTester tester) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );

      for (int i = 0; i < 3; i++) {
        await tapKeycap(tester);
      }

      expect(
        tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data,
        '3',
      );
      // State agrees with the rendered text.
      expect(container.read(statsProvider).totalClicks, 3);
    });
  });

  group('Switch selection (AC6)', () {
    testWidgets('tapping 적축 selects red and updates the keycap label', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpApp(
        tester,
        prefs: prefs,
        player: player,
      );

      // Starts on blue.
      expect(container.read(settingsProvider).selectedSwitchId, 'blue');
      expect(find.text(SwitchCatalog.red.nameEn), findsNothing);

      await tester.tap(find.byKey(HomeScreen.switchChipKey('red')));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).selectedSwitchId, 'red');
      // Keycap label now reflects the red switch.
      expect(find.text(SwitchCatalog.red.nameEn), findsOneWidget);
      expect(find.text(SwitchCatalog.blue.nameEn), findsNothing);
    });

    testWidgets(
      'a later chip (speedSilver) is reachable by scrolling and selectable',
      (WidgetTester tester) async {
        final ProviderContainer container = await pumpApp(
          tester,
          prefs: prefs,
          player: player,
        );

        final Finder chip = find.byKey(HomeScreen.switchChipKey('speedSilver'));
        // The chip exists in the tree (all eleven are built at once) but starts
        // scrolled off-screen; bring it into view by scrolling the horizontal
        // selector, then tap it.
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();

        await tester.tap(chip);
        await tester.pumpAndSettle();

        expect(
          container.read(settingsProvider).selectedSwitchId,
          'speedSilver',
        );
        // Keycap label now reflects the speed silver switch.
        expect(find.text(SwitchCatalog.speedSilver.nameEn), findsOneWidget);
      },
    );
  });

  group('Press wiring: sound + haptics + stats (AC4)', () {
    testWidgets(
      'press-down plays the down clip, fires a haptic, and registers a click; '
      'release plays the up clip',
      (WidgetTester tester) async {
        await pumpApp(tester, prefs: prefs, player: player);

        final int downId = backend.idByAsset[SwitchCatalog.blue.downAsset]!;
        final int upId = backend.idByAsset[SwitchCatalog.blue.upAsset]!;

        // Press down only (do not release yet) to isolate the down side.
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        await tester.pump();

        // Down clip played, exactly one haptic fired, one click registered.
        expect(backend.played, hasLength(1));
        expect(backend.played.single.soundId, downId);
        expect(vibrateArgs, hasLength(1));
        expect(
          tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data,
          '1',
        );

        // Release plays the up clip (no extra haptic, no extra click).
        await gesture.up();
        await tester.pump();

        expect(backend.played, hasLength(2));
        expect(backend.played[1].soundId, upId);
        expect(vibrateArgs, hasLength(1));
        expect(
          tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data,
          '1',
        );
      },
    );

    testWidgets(
      'sound disabled in settings suppresses playback but still counts',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'settings.soundEnabled': false,
        });
        final SharedPreferences mutedPrefs =
            await SharedPreferences.getInstance();

        await pumpApp(tester, prefs: mutedPrefs, player: player);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byKey(Keycap.innerCapKey)),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // No sound played, but the click still counted.
        expect(backend.played, isEmpty);
        expect(
          tester.widget<Text>(find.byKey(HomeScreen.totalStatKey)).data,
          '1',
        );
      },
    );
  });
}
