import 'package:cliker/persistence/settings_store.dart';
import 'package:cliker/providers/stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a [ProviderContainer] over a fresh mock-prefs instance seeded with
/// [initial].
Future<ProviderContainer> containerWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Builds another container over the *current* mock prefs (no reseed),
/// simulating an app restart that shares the same on-disk store.
Future<ProviderContainer> restartedContainer() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatsNotifier defaults from empty prefs (AC1)', () {
    test('all counters start at 0', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );

      final Stats stats = container.read(statsProvider);
      expect(stats.totalClicks, 0);
      expect(stats.sessionClicks, 0);
      expect(stats.cpm, 0);
      expect(stats.bestCpm, 0);
    });

    test('loads persisted totalClicks and bestCpm', () async {
      final ProviderContainer container = await containerWith(<String, Object>{
        'stats.totalClicks': 42,
        'stats.bestCpm': 7,
      });

      final Stats stats = container.read(statsProvider);
      expect(stats.totalClicks, 42);
      expect(stats.bestCpm, 7);
      // Session figures are always in-memory, so they reset on (re)build.
      expect(stats.sessionClicks, 0);
      expect(stats.cpm, 0);
    });
  });

  group('registerClick counts + persistence (AC3)', () {
    test('increments total and session by 1 per click', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );
      final StatsNotifier notifier = container.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      notifier.registerClick(t0);
      notifier.registerClick(t0.add(const Duration(seconds: 1)));
      notifier.registerClick(t0.add(const Duration(seconds: 2)));

      final Stats stats = container.read(statsProvider);
      expect(stats.totalClicks, 3);
      expect(stats.sessionClicks, 3);
    });

    test(
      'totalClicks persists across restart but sessionClicks resets to 0',
      () async {
        final ProviderContainer first = await containerWith(<String, Object>{});
        final StatsNotifier notifier = first.read(statsProvider.notifier);

        final DateTime t0 = DateTime(2026, 6, 22, 12);
        notifier.registerClick(t0);
        notifier.registerClick(t0.add(const Duration(seconds: 1)));
        expect(first.read(statsProvider).totalClicks, 2);
        expect(first.read(statsProvider).sessionClicks, 2);

        final ProviderContainer second = await restartedContainer();
        final Stats after = second.read(statsProvider);
        expect(after.totalClicks, 2, reason: 'total persisted');
        expect(after.sessionClicks, 0, reason: 'session is in-memory');
      },
    );
  });

  group('CPM trailing-60s window + bestCpm (AC4)', () {
    test('cpm counts clicks within the trailing 60s window', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );
      final StatsNotifier notifier = container.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      // 5 clicks, one every 10s -> spans 0s..40s, all within 60s of the last.
      for (int i = 0; i < 5; i++) {
        notifier.registerClick(t0.add(Duration(seconds: i * 10)));
      }
      expect(container.read(statsProvider).cpm, 5);
    });

    test('clicks older than 60s age out of the window', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );
      final StatsNotifier notifier = container.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      notifier.registerClick(t0); // 0s  -> ages out by the last click
      notifier.registerClick(t0.add(const Duration(seconds: 30)));
      notifier.registerClick(t0.add(const Duration(seconds: 50)));
      // Last click at 70s: window is (10s, 70s]; the 0s click drops, 30s/50s
      // remain, plus this one -> 3.
      notifier.registerClick(t0.add(const Duration(seconds: 70)));

      expect(container.read(statsProvider).cpm, 3);
    });

    test('a click exactly 60s old is excluded (strict window)', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );
      final StatsNotifier notifier = container.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      notifier.registerClick(t0); // exactly 60s before the next click
      notifier.registerClick(t0.add(const Duration(seconds: 60)));

      // The 0s click is exactly at the cutoff -> excluded; only the new one.
      expect(container.read(statsProvider).cpm, 1);
    });

    test('bestCpm tracks the observed maximum and then holds', () async {
      final ProviderContainer container = await containerWith(
        <String, Object>{},
      );
      final StatsNotifier notifier = container.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      // Burst of 4 within a few seconds -> cpm climbs to 4.
      for (int i = 0; i < 4; i++) {
        notifier.registerClick(t0.add(Duration(seconds: i)));
      }
      expect(container.read(statsProvider).cpm, 4);
      expect(container.read(statsProvider).bestCpm, 4);

      // Long gap then a lone click far later -> cpm drops, best holds at 4.
      notifier.registerClick(t0.add(const Duration(minutes: 10)));
      expect(container.read(statsProvider).cpm, 1);
      expect(container.read(statsProvider).bestCpm, 4);
    });

    test('bestCpm persists across restart', () async {
      final ProviderContainer first = await containerWith(<String, Object>{});
      final StatsNotifier notifier = first.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      for (int i = 0; i < 3; i++) {
        notifier.registerClick(t0.add(Duration(seconds: i)));
      }
      expect(first.read(statsProvider).bestCpm, 3);

      final ProviderContainer second = await restartedContainer();
      expect(second.read(statsProvider).bestCpm, 3);
      // cpm is in-memory -> back to 0 after restart.
      expect(second.read(statsProvider).cpm, 0);
    });
  });

  group('resetStats zeroes everything + persists (AC5)', () {
    test('resets in-memory state and persisted figures', () async {
      final ProviderContainer first = await containerWith(<String, Object>{
        'stats.totalClicks': 100,
        'stats.bestCpm': 9,
      });
      final StatsNotifier notifier = first.read(statsProvider.notifier);

      final DateTime t0 = DateTime(2026, 6, 22, 12);
      notifier.registerClick(t0);
      notifier.registerClick(t0.add(const Duration(seconds: 1)));
      expect(first.read(statsProvider).totalClicks, 102);

      notifier.resetStats();
      final Stats reset = first.read(statsProvider);
      expect(reset.totalClicks, 0);
      expect(reset.sessionClicks, 0);
      expect(reset.cpm, 0);
      expect(reset.bestCpm, 0);

      // Persisted zeros survive a restart.
      final ProviderContainer second = await restartedContainer();
      final Stats after = second.read(statsProvider);
      expect(after.totalClicks, 0);
      expect(after.bestCpm, 0);
    });
  });

  group('Stats value semantics', () {
    test('copyWith changes only named fields', () {
      const Stats base = Stats(
        totalClicks: 10,
        sessionClicks: 5,
        cpm: 3,
        bestCpm: 8,
      );
      final Stats changed = base.copyWith(cpm: 4);
      expect(changed.cpm, 4);
      expect(changed.totalClicks, base.totalClicks);
      expect(changed.sessionClicks, base.sessionClicks);
      expect(changed.bestCpm, base.bestCpm);
    });

    test('equality and hashCode are value-based', () {
      const Stats a = Stats(
        totalClicks: 1,
        sessionClicks: 2,
        cpm: 3,
        bestCpm: 4,
      );
      const Stats b = Stats(
        totalClicks: 1,
        sessionClicks: 2,
        cpm: 3,
        bestCpm: 4,
      );
      const Stats c = Stats(
        totalClicks: 9,
        sessionClicks: 2,
        cpm: 3,
        bestCpm: 4,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
