import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/audio/dynamic_click_engine.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every backend call so a test can assert exactly which sounds played,
/// in order, without touching platform channels. Mirrors the fake the player's
/// own unit tests use.
class FakeBackend implements SoundBackend {
  final List<({int soundId, double volume})> played =
      <({int soundId, double volume})>[];
  final Map<String, int> idByAsset = <String, int>{};
  int _next = 0;

  @override
  Future<int> load(String asset) async =>
      idByAsset.putIfAbsent(asset, () => _next++);

  @override
  Future<void> play(int soundId, {double volume = 1.0}) async {
    played.add((soundId: soundId, volume: volume));
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  // Each backend.load assigns a stable id; resolve the ids for the assets we
  // assert on once the player is initialized.
  late FakeBackend backend;
  late ClickSoundPlayer player;
  late DynamicClickEngine engine;

  /// The soundIds played so far, in order.
  List<int> playedIds() => backend.played
      .map((({int soundId, double volume}) p) => p.soundId)
      .toList();

  int idOf(String asset) => backend.idByAsset[asset]!;

  setUp(() async {
    backend = FakeBackend();
    player = ClickSoundPlayer(backend);
    await player.init();
    engine = DynamicClickEngine(player);
  });

  group('static mapping helpers', () {
    test('spreadFor: intensity alone drives spread when force is null', () {
      expect(DynamicClickEngine.spreadFor(null, 0.0), 0.0);
      expect(DynamicClickEngine.spreadFor(null, 0.5), 0.5);
      expect(DynamicClickEngine.spreadFor(null, 1.0), 1.0);
    });

    test('spreadFor: a softer press spreads more, a firmer one less', () {
      // 50/50 blend of intensity and (1 - force).
      const double i = 0.5;
      final double soft = DynamicClickEngine.spreadFor(0.0, i); // 0.5*.5+0.5*1
      final double firm = DynamicClickEngine.spreadFor(1.0, i); // 0.5*.5+0.5*0
      expect(soft, 0.75);
      expect(firm, 0.25);
      expect(soft, greaterThan(firm));
    });

    test('delays widen with spread and are ordered click < bottom', () {
      // A firm press (low spread) is snappier than a soft press (high spread).
      expect(
        DynamicClickEngine.clickDelayFor(1.0, 0.5),
        lessThan(DynamicClickEngine.clickDelayFor(0.0, 0.5)),
      );
      expect(
        DynamicClickEngine.bottomDelayFor(1.0, 0.5),
        lessThan(DynamicClickEngine.bottomDelayFor(0.0, 0.5)),
      );
      // For any given press the actuation click precedes the bottom-out.
      expect(
        DynamicClickEngine.clickDelayFor(null, 0.5),
        lessThan(DynamicClickEngine.bottomDelayFor(null, 0.5)),
      );
    });

    test('volumeFor: firm/unknown loudest, soft quietest', () {
      expect(DynamicClickEngine.volumeFor(null), DynamicClickEngine.volumeMax);
      expect(DynamicClickEngine.volumeFor(1.0), DynamicClickEngine.volumeMax);
      expect(DynamicClickEngine.volumeFor(0.0), DynamicClickEngine.volumeMin);
      expect(
        DynamicClickEngine.volumeFor(0.5),
        moreOrLessEquals(
          (DynamicClickEngine.volumeMin + DynamicClickEngine.volumeMax) / 2,
        ),
      );
      // A soft press must never be silent.
      expect(DynamicClickEngine.volumeMin, greaterThan(0.0));
    });

    test(
      'delays hit the named constants at the extremes (not just monotonic)',
      () {
        // Pin absolute values so a uniform rescale or an inverted lerp is caught.
        expect(
          DynamicClickEngine.clickDelayFor(null, 0.0),
          DynamicClickEngine.clickDelayMin,
        );
        expect(
          DynamicClickEngine.clickDelayFor(null, 1.0),
          DynamicClickEngine.clickDelayMax,
        );
        expect(
          DynamicClickEngine.bottomDelayFor(null, 0.0),
          DynamicClickEngine.bottomDelayMin,
        );
        expect(
          DynamicClickEngine.bottomDelayFor(null, 1.0),
          DynamicClickEngine.bottomDelayMax,
        );
        // Click precedes bottom-out at BOTH extremes, not only the 0.5 midpoint.
        for (final double i in <double>[0.0, 0.5, 1.0]) {
          expect(
            DynamicClickEngine.clickDelayFor(null, i),
            lessThan(DynamicClickEngine.bottomDelayFor(null, i)),
            reason: 'click must precede bottom at intensity $i',
          );
        }
      },
    );
  });

  group('clicky switch (blue) — full onset → click → bottom decomposition', () {
    test('held past bottom-out plays "따~알~깍" then release', () {
      fakeAsync((FakeAsync async) {
        const SwitchType s = SwitchCatalog.blue;
        final int onset = idOf(s.onsetAsset);
        final int click = idOf(s.clickAsset!);
        final int bottom = idOf(s.bottomAsset);
        final int up = idOf(s.upAsset);

        engine.pressDown(s, intensity: 0.5);
        // Onset is instant.
        expect(playedIds(), <int>[onset]);

        // Advance past the actuation click.
        async.elapse(DynamicClickEngine.clickDelayFor(null, 0.5));
        expect(playedIds(), <int>[onset, click]);

        // Advance past the bottom-out.
        async.elapse(DynamicClickEngine.bottomDelayFor(null, 0.5));
        expect(playedIds(), <int>[onset, click, bottom]);

        // Release adds the up clip; no crisp down (it fully decomposed).
        engine.pressUp();
        expect(playedIds(), <int>[onset, click, bottom, up]);

        // No stray timers remain.
        async.elapse(const Duration(seconds: 1));
        expect(playedIds(), <int>[onset, click, bottom, up]);
      });
    });
  });

  group('clicky switch (blue) — quick stab collapses to a crisp "딸깍"', () {
    test('released before the click fires plays onset + down + up', () {
      fakeAsync((FakeAsync async) {
        const SwitchType s = SwitchCatalog.blue;
        final int onset = idOf(s.onsetAsset);
        final int down = idOf(s.downAsset);
        final int up = idOf(s.upAsset);

        engine.pressDown(s, intensity: 0.5);
        expect(playedIds(), <int>[onset]);

        // Release immediately — neither click nor bottom has fired.
        engine.pressUp();
        expect(playedIds(), <int>[onset, down, up]);

        // The cancelled click/bottom timers must never fire afterward.
        async.elapse(const Duration(seconds: 1));
        expect(playedIds(), <int>[onset, down, up]);
      });
    });
  });

  group('clicky switch (blue) — medium press: actuation, no bottom-out', () {
    test('released after click but before bottom plays onset + click + up', () {
      fakeAsync((FakeAsync async) {
        const SwitchType s = SwitchCatalog.blue;
        final int onset = idOf(s.onsetAsset);
        final int click = idOf(s.clickAsset!);
        final int up = idOf(s.upAsset);

        engine.pressDown(s, intensity: 0.5);
        async.elapse(DynamicClickEngine.clickDelayFor(null, 0.5));
        expect(playedIds(), <int>[onset, click]);

        // Release before bottom-out: no thud, no crisp down — just "따알".
        engine.pressUp();
        expect(playedIds(), <int>[onset, click, up]);

        async.elapse(const Duration(seconds: 1));
        expect(playedIds(), <int>[onset, click, up]);
      });
    });
  });

  group('linear switch (red) — no actuation click jacket', () {
    test('full hold plays onset → bottom (no click) → up', () {
      fakeAsync((FakeAsync async) {
        const SwitchType s = SwitchCatalog.red;
        expect(s.clickAsset, isNull);
        final int onset = idOf(s.onsetAsset);
        final int bottom = idOf(s.bottomAsset);
        final int up = idOf(s.upAsset);

        engine.pressDown(s, intensity: 0.5);
        expect(playedIds(), <int>[onset]);

        async.elapse(DynamicClickEngine.bottomDelayFor(null, 0.5));
        expect(playedIds(), <int>[onset, bottom]);

        engine.pressUp();
        expect(playedIds(), <int>[onset, bottom, up]);
      });
    });

    test('quick stab still lands a crisp down', () {
      fakeAsync((FakeAsync async) {
        const SwitchType s = SwitchCatalog.red;
        final int onset = idOf(s.onsetAsset);
        final int down = idOf(s.downAsset);
        final int up = idOf(s.upAsset);

        engine.pressDown(s, intensity: 0.5);
        engine.pressUp();
        expect(playedIds(), <int>[onset, down, up]);

        async.elapse(const Duration(seconds: 1));
        expect(playedIds(), <int>[onset, down, up]);
      });
    });
  });

  group('force modulates volume', () {
    test(
      'a soft press plays quieter than a firm one (every stem, not just onset)',
      () {
        fakeAsync((FakeAsync _) {
          // Quick stab on a linear switch → onset + down + up, all at one volume.
          engine.pressDown(SwitchCatalog.red, force: 0.0, intensity: 0.5);
          engine.pressUp();
          final List<double> soft = backend.played
              .map((p) => p.volume)
              .toList();

          backend.played.clear();
          engine.pressDown(SwitchCatalog.red, force: 1.0, intensity: 0.5);
          engine.pressUp();
          final List<double> firm = backend.played
              .map((p) => p.volume)
              .toList();

          // EVERY clip in the press carries the one modulated volume — a per-stem
          // or onset-only volume regression would break this, not just .first.
          expect(soft, isNotEmpty);
          expect(soft, everyElement(DynamicClickEngine.volumeMin));
          expect(firm, isNotEmpty);
          expect(firm, everyElement(DynamicClickEngine.volumeMax));
          expect(
            DynamicClickEngine.volumeMin,
            lessThan(DynamicClickEngine.volumeMax),
          );
        });
      },
    );

    test(
      'a full clicky hold carries one uniform volume across onset/click/bottom/up',
      () {
        fakeAsync((FakeAsync async) {
          engine.pressDown(SwitchCatalog.blue, force: 0.0, intensity: 0.5);
          async.elapse(
            DynamicClickEngine.bottomDelayFor(0.0, 0.5) +
                const Duration(milliseconds: 1),
          );
          engine.pressUp();
          // onset, click, bottom, up — all four at volumeMin (force 0.0).
          expect(backend.played, hasLength(4));
          expect(
            backend.played.map((p) => p.volume),
            everyElement(DynamicClickEngine.volumeMin),
          );
        });
      },
    );
  });

  group('robustness', () {
    test('pressUp with no active press is a safe no-op', () {
      fakeAsync((FakeAsync _) {
        engine.pressUp();
        expect(playedIds(), isEmpty);
      });
    });

    test('dispose cancels in-flight timers (no later plays)', () {
      fakeAsync((FakeAsync async) {
        final int onset = idOf(SwitchCatalog.blue.onsetAsset);
        engine.pressDown(SwitchCatalog.blue, intensity: 0.5);
        expect(playedIds(), <int>[onset]);

        engine.dispose();
        async.elapse(const Duration(seconds: 1));
        // Only the instant onset ever played; click/bottom were cancelled.
        expect(playedIds(), <int>[onset]);
      });
    });

    test('a new press cancels a prior unbalanced schedule', () {
      fakeAsync((FakeAsync async) {
        final int onset = idOf(SwitchCatalog.blue.onsetAsset);
        // First press never balanced by a pressUp.
        engine.pressDown(SwitchCatalog.blue, intensity: 0.5);
        // Second press before the first's timers fire.
        engine.pressDown(SwitchCatalog.blue, intensity: 0.5);
        // Two onsets so far (one per pressDown); the first's click/bottom were
        // cancelled by the second pressDown.
        expect(playedIds(), <int>[onset, onset]);

        // Let the SECOND press fully decompose to confirm only one set fires.
        final int click = idOf(SwitchCatalog.blue.clickAsset!);
        final int bottom = idOf(SwitchCatalog.blue.bottomAsset);
        async.elapse(
          DynamicClickEngine.bottomDelayFor(null, 0.5) +
              const Duration(milliseconds: 1),
        );
        expect(playedIds(), <int>[onset, onset, click, bottom]);
      });
    });
  });
}
