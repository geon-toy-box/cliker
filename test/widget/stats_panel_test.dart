import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/stats_providers.dart';
import 'package:cliker/theme/app_theme.dart';
import 'package:cliker/widgets/stats_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hosts the [StatsPanel] under the real [appTheme] with [SharedPreferences]
/// overridden, returning the [ProviderContainer] so tests can drive
/// [statsProvider] directly. A [MaterialApp] (not just a bare widget) is used so
/// the reset confirm dialog has a [Navigator] to push onto.
Future<ProviderContainer> pumpPanel(
  WidgetTester tester, {
  required SharedPreferences prefs,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appTheme(),
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: StatsPanel()),
      ),
    ),
  );
  return container;
}

/// Reads the rendered string of the value [Text] carrying [key].
String valueOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('AC3: panel shows exactly two values (전체 클릭수 + RPM)', () {
    testWidgets('only total and rpm tiles exist, both starting at 0', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester, prefs: prefs);

      // Exactly the two spec'd keys are present.
      expect(find.byKey(StatsPanel.totalStatKey), findsOneWidget);
      expect(find.byKey(StatsPanel.rpmStatKey), findsOneWidget);

      // The old four-tile keys are gone (no session/cpm/best tiles).
      expect(find.byKey(const Key('stat-session')), findsNothing);
      expect(find.byKey(const Key('stat-cpm')), findsNothing);
      expect(find.byKey(const Key('stat-best')), findsNothing);

      // Labels render alongside the two values.
      expect(find.text('전체 클릭수'), findsOneWidget);
      expect(find.text('RPM'), findsOneWidget);

      // Cold start: both counters read 0.
      expect(valueOf(tester, StatsPanel.totalStatKey), '0');
      expect(valueOf(tester, StatsPanel.rpmStatKey), '0');

      expect(tester.takeException(), isNull);
    });

    testWidgets('seeded lifetime total renders thousands-formatted', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'stats.totalClicks': 12345,
      });
      final SharedPreferences seeded = await SharedPreferences.getInstance();

      await pumpPanel(tester, prefs: seeded);

      expect(valueOf(tester, StatsPanel.totalStatKey), '12,345');
    });
  });

  group('AC3: registering clicks increments total and RPM', () {
    testWidgets('one click drives total to 1 and RPM to 1', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await pumpPanel(tester, prefs: prefs);

      container.read(statsProvider.notifier).registerClick(DateTime.now());
      await tester.pump();

      expect(valueOf(tester, StatsPanel.totalStatKey), '1');
      expect(valueOf(tester, StatsPanel.rpmStatKey), '1');
      expect(container.read(statsProvider).totalClicks, 1);
      expect(container.read(statsProvider).cpm, 1);
    });

    testWidgets('crossing 1000 applies the thousands separator to total', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'stats.totalClicks': 1233,
      });
      final SharedPreferences seeded = await SharedPreferences.getInstance();
      final ProviderContainer container = await pumpPanel(
        tester,
        prefs: seeded,
      );

      expect(valueOf(tester, StatsPanel.totalStatKey), '1,233');

      container.read(statsProvider.notifier).registerClick(DateTime.now());
      await tester.pump();

      expect(valueOf(tester, StatsPanel.totalStatKey), '1,234');
    });
  });

  group(
    'AC4: reset button → confirm dialog → cancel keeps / confirm zeroes',
    () {
      testWidgets('cancel dismisses the dialog and keeps the values', (
        WidgetTester tester,
      ) async {
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: prefs,
        );

        for (int i = 0; i < 5; i++) {
          container.read(statsProvider.notifier).registerClick(DateTime.now());
        }
        await tester.pump();
        expect(valueOf(tester, StatsPanel.totalStatKey), '5');

        await tester.tap(find.byKey(StatsPanel.resetButtonKey));
        await tester.pumpAndSettle();
        expect(find.byKey(StatsPanel.resetDialogKey), findsOneWidget);

        await tester.tap(find.byKey(StatsPanel.resetCancelKey));
        await tester.pumpAndSettle();

        expect(find.byKey(StatsPanel.resetDialogKey), findsNothing);
        expect(valueOf(tester, StatsPanel.totalStatKey), '5');
        expect(container.read(statsProvider).totalClicks, 5);
      });

      testWidgets('confirm zeroes total + RPM and persists total=0', (
        WidgetTester tester,
      ) async {
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: prefs,
        );

        final DateTime base = DateTime(2026, 6, 22, 12);
        for (int i = 0; i < 7; i++) {
          container
              .read(statsProvider.notifier)
              .registerClick(base.add(Duration(seconds: i)));
        }
        await tester.pump();
        final Stats before = container.read(statsProvider);
        expect(before.totalClicks, 7);
        expect(before.cpm, greaterThan(0));

        await tester.tap(find.byKey(StatsPanel.resetButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(StatsPanel.resetConfirmKey));
        await tester.pumpAndSettle();

        // Both displayed values are now 0.
        expect(valueOf(tester, StatsPanel.totalStatKey), '0');
        expect(valueOf(tester, StatsPanel.rpmStatKey), '0');

        // Provider state zeroed.
        final Stats after = container.read(statsProvider);
        expect(after.totalClicks, 0);
        expect(after.cpm, 0);

        // Persisted: a fresh container over the same prefs still reads 0.
        final SharedPreferences freshPrefs =
            await SharedPreferences.getInstance();
        final ProviderContainer second = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(freshPrefs)],
        );
        addTearDown(second.dispose);
        expect(second.read(statsProvider).totalClicks, 0);
      });

      testWidgets('barrier dismiss (tap outside) keeps the values', (
        WidgetTester tester,
      ) async {
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: prefs,
        );
        container.read(statsProvider.notifier).registerClick(DateTime.now());
        await tester.pump();

        await tester.tap(find.byKey(StatsPanel.resetButtonKey));
        await tester.pumpAndSettle();
        expect(find.byKey(StatsPanel.resetDialogKey), findsOneWidget);

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.byKey(StatsPanel.resetDialogKey), findsNothing);
        expect(container.read(statsProvider).totalClicks, 1);
      });
    },
  );
}
