import 'package:cliker/app.dart';
import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/screens/home_screen.dart';
import 'package:cliker/widgets/keycap.dart';
import 'package:cliker/widgets/switch_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records nothing meaningful — the menu never plays sound — but satisfies the
/// [ClickSoundPlayer] dependency the full app wires up without touching a
/// platform channel.
class _SilentBackend implements SoundBackend {
  int _next = 0;

  @override
  Future<int> load(String asset) async => _next++;

  @override
  Future<void> play(int soundId, {double volume = 1.0}) async {}

  @override
  Future<void> dispose() async {}
}

/// Mounts the [SwitchMenu] directly (no home screen) under a [ProviderScope]
/// backed by [prefs], so the menu's own rendering can be asserted in isolation.
Future<void> pumpMenu(
  WidgetTester tester, {
  required SharedPreferences prefs,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: Scaffold(body: SwitchMenu())),
    ),
  );
  await tester.pumpAndSettle();
}

/// Reads the live [Keycap] from the rendered full app.
Keycap _keycap(WidgetTester tester) =>
    tester.widget<Keycap>(find.byType(Keycap));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('SwitchMenu renders every switch row (AC4)', () {
    testWidgets('all 13 switch-chip-<id> rows are present', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, prefs: prefs);

      expect(SwitchCatalog.all, hasLength(13));
      for (final SwitchType s in SwitchCatalog.all) {
        // The row may be scrolled off-screen but must exist in the tree
        // (SingleChildScrollView keeps every row built).
        expect(
          find.byKey(SwitchMenu.switchChipKey(s.id)),
          findsOneWidget,
          reason: 'row for ${s.id}',
        );
      }
    });

    testWidgets(
      'each row shows kind · force, feel (description) and 추천: recommendedFor',
      (WidgetTester tester) async {
        await pumpMenu(tester, prefs: prefs);

        for (final SwitchType s in SwitchCatalog.all) {
          final Finder row = find.byKey(SwitchMenu.switchChipKey(s.id));

          // Heading: "nameKo (nameEn)".
          expect(
            find.descendant(
              of: row,
              matching: find.text('${s.nameKo} (${s.nameEn})'),
            ),
            findsOneWidget,
            reason: '${s.id} heading',
          );

          // Meta line begins with the force in cN.
          expect(
            find.descendant(
              of: row,
              matching: find.textContaining('${s.forceCn}cN'),
            ),
            findsOneWidget,
            reason: '${s.id} force',
          );

          // Feel (느낌) one-liner.
          expect(
            find.descendant(of: row, matching: find.text(s.description)),
            findsOneWidget,
            reason: '${s.id} feel',
          );

          // Recommended use, prefixed "추천: ".
          expect(
            find.descendant(
              of: row,
              matching: find.text('추천: ${s.recommendedFor}'),
            ),
            findsOneWidget,
            reason: '${s.id} recommendedFor',
          );
        }
      },
    );

    testWidgets(
      'the magnetic row carries its "무접점" feel and "e스포츠" recommendation',
      (WidgetTester tester) async {
        await pumpMenu(tester, prefs: prefs);

        final Finder row = find.byKey(SwitchMenu.switchChipKey('magnetic'));
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.textContaining('무접점')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.textContaining('e스포츠')),
          findsOneWidget,
        );
      },
    );

    testWidgets('each row renders a 5-segment loudness bar', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, prefs: prefs);

      // One volume icon per row marks the loudness bar; 13 rows => 13 icons.
      expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(13));
    });
  });

  group('Selecting a new switch updates settings and the keycap (AC4)', () {
    testWidgets(
      'opening the menu and tapping switch-chip-yellow selects yellow and '
      'updates the keycap stem color + label',
      (WidgetTester tester) async {
        final _SilentBackend backend = _SilentBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);
        await player.init();

        final ProviderContainer container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clickSoundPlayerProvider.overrideWithValue(player),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ClikerApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Cold start is blue: keycap shows blue's name + stem color.
        expect(container.read(settingsProvider).selectedSwitchId, 'blue');
        expect(_keycap(tester).stemColor, SwitchCatalog.blue.stemColor);
        expect(_keycap(tester).label, SwitchCatalog.blue.nameKo);

        // Open the menu, bring the yellow row into view, and tap it.
        await tester.tap(find.byKey(HomeScreen.switchMenuButtonKey));
        await tester.pumpAndSettle();

        final Finder chip = find.byKey(HomeScreen.switchChipKey('yellow'));
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();

        // Selection persisted, menu closed, keycap now reflects yellow.
        expect(container.read(settingsProvider).selectedSwitchId, 'yellow');
        expect(find.byKey(SwitchMenu.sheetKey), findsNothing);
        expect(_keycap(tester).stemColor, SwitchCatalog.yellow.stemColor);
        expect(_keycap(tester).label, SwitchCatalog.yellow.nameKo);
      },
    );

    testWidgets('the selected row is highlighted with a check', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.selectedSwitchId': 'magnetic',
      });
      final SharedPreferences seeded = await SharedPreferences.getInstance();

      await pumpMenu(tester, prefs: seeded);

      // The check icon marks the one selected row (magnetic), and no other.
      final Finder selectedRow = find.byKey(
        SwitchMenu.switchChipKey('magnetic'),
      );
      expect(
        find.descendant(
          of: selectedRow,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
