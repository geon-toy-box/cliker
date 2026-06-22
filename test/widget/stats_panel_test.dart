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

  group('AC1: panel shows all four values with their keys', () {
    testWidgets('total/session/CPM/best are present and start at 0', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester, prefs: prefs);

      expect(find.byKey(StatsPanel.totalStatKey), findsOneWidget);
      expect(find.byKey(StatsPanel.sessionStatKey), findsOneWidget);
      expect(find.byKey(StatsPanel.cpmStatKey), findsOneWidget);
      expect(find.byKey(StatsPanel.bestStatKey), findsOneWidget);

      // Labels render alongside the values.
      expect(find.text('누적'), findsOneWidget);
      expect(find.text('세션'), findsOneWidget);
      expect(find.text('CPM'), findsOneWidget);
      expect(find.text('최고 CPM'), findsOneWidget);

      // Cold start: every counter reads 0.
      expect(valueOf(tester, StatsPanel.totalStatKey), '0');
      expect(valueOf(tester, StatsPanel.sessionStatKey), '0');
      expect(valueOf(tester, StatsPanel.cpmStatKey), '0');
      expect(valueOf(tester, StatsPanel.bestStatKey), '0');

      expect(tester.takeException(), isNull);
    });

    testWidgets('seeded lifetime total renders thousands-formatted', (
      WidgetTester tester,
    ) async {
      // bestCpm + totalClicks persist; seed them and confirm the panel reads
      // them back with thousands separators.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'stats.totalClicks': 12345,
        'stats.bestCpm': 1234,
      });
      final SharedPreferences seeded = await SharedPreferences.getInstance();

      await pumpPanel(tester, prefs: seeded);

      expect(valueOf(tester, StatsPanel.totalStatKey), '12,345');
      expect(valueOf(tester, StatsPanel.bestStatKey), '1,234');
    });
  });

  group(
    'AC2: registering clicks increments + thousands-formats the display',
    () {
      testWidgets('one click drives total and session to 1', (
        WidgetTester tester,
      ) async {
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: prefs,
        );

        container.read(statsProvider.notifier).registerClick(DateTime.now());
        await tester.pump();

        expect(valueOf(tester, StatsPanel.totalStatKey), '1');
        expect(valueOf(tester, StatsPanel.sessionStatKey), '1');
        expect(container.read(statsProvider).totalClicks, 1);
      });

      testWidgets('crossing 1000 applies the thousands separator', (
        WidgetTester tester,
      ) async {
        // Seed 1233 lifetime clicks, then register one more → 1,234.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'stats.totalClicks': 1233,
        });
        final SharedPreferences seeded = await SharedPreferences.getInstance();
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: seeded,
        );

        // Before the click: seeded total reads 1,233; session still 0.
        expect(valueOf(tester, StatsPanel.totalStatKey), '1,233');
        expect(valueOf(tester, StatsPanel.sessionStatKey), '0');

        container.read(statsProvider.notifier).registerClick(DateTime.now());
        await tester.pump();

        expect(valueOf(tester, StatsPanel.totalStatKey), '1,234');
        expect(valueOf(tester, StatsPanel.sessionStatKey), '1');
      });
    },
  );

  group(
    'AC3: reset button → confirm dialog → cancel keeps / confirm zeroes',
    () {
      testWidgets('cancel dismisses the dialog and keeps the values', (
        WidgetTester tester,
      ) async {
        final ProviderContainer container = await pumpPanel(
          tester,
          prefs: prefs,
        );

        // Accumulate some clicks.
        for (int i = 0; i < 5; i++) {
          container.read(statsProvider.notifier).registerClick(DateTime.now());
        }
        await tester.pump();
        expect(valueOf(tester, StatsPanel.totalStatKey), '5');

        // Open the dialog.
        await tester.tap(find.byKey(StatsPanel.resetButtonKey));
        await tester.pumpAndSettle();
        expect(find.byKey(StatsPanel.resetDialogKey), findsOneWidget);

        // Cancel: dialog closes, values untouched, provider untouched.
        await tester.tap(find.byKey(StatsPanel.resetCancelKey));
        await tester.pumpAndSettle();

        expect(find.byKey(StatsPanel.resetDialogKey), findsNothing);
        expect(valueOf(tester, StatsPanel.totalStatKey), '5');
        expect(container.read(statsProvider).totalClicks, 5);
      });

      testWidgets(
        'confirm zeroes every value and resets statsProvider (persisted)',
        (WidgetTester tester) async {
          final ProviderContainer container = await pumpPanel(
            tester,
            prefs: prefs,
          );

          // Build up total/session/cpm/best.
          final DateTime base = DateTime(2026, 6, 22, 12);
          for (int i = 0; i < 7; i++) {
            container
                .read(statsProvider.notifier)
                .registerClick(base.add(Duration(seconds: i)));
          }
          await tester.pump();
          final Stats before = container.read(statsProvider);
          expect(before.totalClicks, 7);
          expect(before.sessionClicks, 7);
          expect(before.cpm, greaterThan(0));
          expect(before.bestCpm, greaterThan(0));

          // Open dialog, confirm.
          await tester.tap(find.byKey(StatsPanel.resetButtonKey));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(StatsPanel.resetConfirmKey));
          await tester.pumpAndSettle();

          // Every displayed value is now 0.
          expect(valueOf(tester, StatsPanel.totalStatKey), '0');
          expect(valueOf(tester, StatsPanel.sessionStatKey), '0');
          expect(valueOf(tester, StatsPanel.cpmStatKey), '0');
          expect(valueOf(tester, StatsPanel.bestStatKey), '0');

          // Provider state zeroed.
          final Stats after = container.read(statsProvider);
          expect(after.totalClicks, 0);
          expect(after.sessionClicks, 0);
          expect(after.cpm, 0);
          expect(after.bestCpm, 0);

          // Persisted: a fresh container over the same prefs still reads 0
          // (the lifetime figures were cleared, not just the in-memory state).
          final SharedPreferences freshPrefs =
              await SharedPreferences.getInstance();
          final ProviderContainer second = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(freshPrefs),
            ],
          );
          addTearDown(second.dispose);
          expect(second.read(statsProvider).totalClicks, 0);
          expect(second.read(statsProvider).bestCpm, 0);
        },
      );

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

        // Tap the barrier (top-left corner, outside the dialog).
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        expect(find.byKey(StatsPanel.resetDialogKey), findsNothing);
        expect(container.read(statsProvider).totalClicks, 1);
      });
    },
  );
}
