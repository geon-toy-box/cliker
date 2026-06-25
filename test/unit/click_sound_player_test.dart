import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every call so tests can assert exactly what the player asked the
/// backend to do. [load] hands back a distinct, stable id per asset so the
/// player's asset→soundId mapping is observable.
class FakeBackend implements SoundBackend {
  /// Asset paths passed to [load], in call order.
  final List<String> loaded = <String>[];

  /// (soundId, volume) pairs passed to [play], in call order.
  final List<({int soundId, double volume})> played =
      <({int soundId, double volume})>[];

  bool disposed = false;

  /// Stable id assigned to each loaded asset (assignment order: 0, 1, 2, ...).
  final Map<String, int> idByAsset = <String, int>{};
  int _next = 0;

  @override
  Future<int> load(String asset) async {
    loaded.add(asset);
    final int id = idByAsset.putIfAbsent(asset, () => _next++);
    return id;
  }

  @override
  Future<void> play(int soundId, {double volume = 1.0}) async {
    played.add((soundId: soundId, volume: volume));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('ClickSoundPlayer.init (AC1)', () {
    test(
      'loads every catalog clip (down/up + onset/click/bottom) by correct path',
      () async {
        final FakeBackend backend = FakeBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);

        await player.init();

        final List<String> expected = <String>[
          for (final SwitchType s in SwitchCatalog.all) ...s.soundAssets,
        ];

        // 13×(down,up,onset,bottom) + 5 click stems = 57.
        expect(expected, hasLength(57));
        expect(backend.loaded, hasLength(57));
        expect(backend.loaded.toSet(), equals(expected.toSet()));
        // Every loaded path is one of the catalog assets (no stray loads).
        expect(backend.loaded, containsAll(expected));
        expect(player.isInitialized, isTrue);
      },
    );

    test('is idempotent: a second init() does not reload', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);

      await player.init();
      await player.init();

      expect(backend.loaded, hasLength(57));
    });
  });

  group('ClickSoundPlayer.playDown / playUp (AC2)', () {
    test(
      'plays the soundId mapped to the switch down/up asset for blue',
      () async {
        final FakeBackend backend = FakeBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);
        await player.init();

        final int blueDownId = backend.idByAsset[SwitchCatalog.blue.downAsset]!;
        final int blueUpId = backend.idByAsset[SwitchCatalog.blue.upAsset]!;

        await player.playDown(SwitchCatalog.blue);
        await player.playUp(SwitchCatalog.blue);

        expect(backend.played, hasLength(2));
        expect(backend.played[0].soundId, blueDownId);
        expect(backend.played[1].soundId, blueUpId);
      },
    );

    test('uses a different soundId for a second switch (red)', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      final int redDownId = backend.idByAsset[SwitchCatalog.red.downAsset]!;
      final int blueDownId = backend.idByAsset[SwitchCatalog.blue.downAsset]!;
      expect(redDownId, isNot(blueDownId));

      await player.playDown(SwitchCatalog.red);

      expect(backend.played, hasLength(1));
      expect(backend.played.single.soundId, redDownId);
    });

    test('forwards the requested volume to the backend', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      await player.playDown(SwitchCatalog.brown, volume: 0.5);

      expect(backend.played.single.volume, 0.5);
    });
  });

  group('ClickSoundPlayer component stems (onset/click/bottom)', () {
    test(
      'plays the onset/click/bottom soundIds mapped to a clicky switch',
      () async {
        final FakeBackend backend = FakeBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);
        await player.init();

        final int onsetId = backend.idByAsset[SwitchCatalog.blue.onsetAsset]!;
        final int clickId = backend.idByAsset[SwitchCatalog.blue.clickAsset!]!;
        final int bottomId = backend.idByAsset[SwitchCatalog.blue.bottomAsset]!;

        await player.playOnset(SwitchCatalog.blue);
        await player.playClick(SwitchCatalog.blue);
        await player.playBottom(SwitchCatalog.blue);

        expect(
          backend.played.map((({int soundId, double volume}) p) => p.soundId),
          <int>[onsetId, clickId, bottomId],
        );
      },
    );

    test(
      'playClick is a no-op for a pure linear switch (no click jacket)',
      () async {
        final FakeBackend backend = FakeBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);
        await player.init();

        // red is linear → clickAsset is null.
        expect(SwitchCatalog.red.clickAsset, isNull);
        await player.playClick(SwitchCatalog.red);

        expect(backend.played, isEmpty);
      },
    );

    test('onset/bottom forward volume; muted suppresses all stems', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      await player.playOnset(SwitchCatalog.red, volume: 0.4);
      await player.playBottom(SwitchCatalog.red, volume: 0.7);
      expect(
        backend.played.map((({int soundId, double volume}) p) => p.volume),
        <double>[0.4, 0.7],
      );

      player.muted = true;
      await player.playOnset(SwitchCatalog.red);
      await player.playClick(SwitchCatalog.blue);
      await player.playBottom(SwitchCatalog.red);
      expect(backend.played, hasLength(2)); // unchanged — all suppressed.
    });
  });

  group('ClickSoundPlayer.muted (AC3)', () {
    test('muted=true suppresses both playDown and playUp', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      player.muted = true;
      await player.playDown(SwitchCatalog.blue);
      await player.playUp(SwitchCatalog.blue);

      expect(backend.played, isEmpty);
    });

    test('unmuting resumes playback', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      player.muted = true;
      await player.playDown(SwitchCatalog.blue);
      expect(backend.played, isEmpty);

      player.muted = false;
      await player.playDown(SwitchCatalog.blue);
      expect(backend.played, hasLength(1));
    });
  });

  group('ClickSoundPlayer robustness', () {
    test('playing before init() is a safe no-op', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);

      await player.playDown(SwitchCatalog.blue);

      expect(backend.played, isEmpty);
    });

    test('dispose() releases the backend and clears init state', () async {
      final FakeBackend backend = FakeBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      await player.init();

      await player.dispose();

      expect(backend.disposed, isTrue);
      expect(player.isInitialized, isFalse);
    });
  });
}
