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
      'loads exactly the 8 catalog down/up assets, by correct path',
      () async {
        final FakeBackend backend = FakeBackend();
        final ClickSoundPlayer player = ClickSoundPlayer(backend);

        await player.init();

        final List<String> expected = <String>[
          for (final SwitchType s in SwitchCatalog.all) ...<String>[
            s.downAsset,
            s.upAsset,
          ],
        ];

        expect(expected, hasLength(8));
        expect(backend.loaded, hasLength(8));
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

      expect(backend.loaded, hasLength(8));
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
