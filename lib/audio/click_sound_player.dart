import 'package:audioplayers/audioplayers.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal sound-playback surface the [ClickSoundPlayer] depends on.
///
/// Pulling the native pool behind this interface lets tests inject a fake and
/// assert exactly which assets are loaded and which sound ids are played,
/// without touching platform channels. The shipping implementation is
/// [AudioPlayersBackend]; tests supply their own.
abstract class SoundBackend {
  /// Loads [asset] (a Flutter asset path) into the pool and returns its sound
  /// id, used later by [play].
  Future<int> load(String asset);

  /// Plays the already-loaded sound identified by [soundId] at [volume]
  /// (0.0–1.0).
  Future<void> play(int soundId, {double volume});

  /// Releases all native resources held by the backend.
  Future<void> dispose();
}

/// [SoundBackend] backed by the `audioplayers` plugin's [AudioPool].
///
/// Each loaded asset gets its own [AudioPool] of a few players in
/// [PlayerMode.lowLatency] (Android `SoundPool` under the hood), so rapid,
/// overlapping presses each grab a free player instead of cutting one another
/// off — the low-latency feel the feature is built around. [load] returns a
/// small integer id that maps back to the asset's pool.
class AudioPlayersBackend implements SoundBackend {
  AudioPlayersBackend({int maxPlayers = 4}) : _maxPlayers = maxPlayers;

  final int _maxPlayers;
  final List<AudioPool> _pools = <AudioPool>[];

  /// Audio attributes for short UI click sounds.
  ///
  /// The critical setting is [AndroidAudioFocus.none]: a fidget clicker fires
  /// many tiny overlapping clips, and requesting media audio focus per play made
  /// each player immediately steal focus from the previous one
  /// (`onAudioFocusChange(-1)`), cutting every ~100ms click off so nothing was
  /// audible. With no focus request the clips overlap freely and the user's
  /// background music is left untouched. Sonification content/usage marks these
  /// as UI sound effects rather than media.
  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
  );

  @override
  Future<int> load(String asset) async {
    // AssetSource auto-prefixes "assets/", so strip a leading "assets/" from
    // the catalog path (e.g. "assets/sounds/blue_down.wav" -> "sounds/...").
    final String path = asset.startsWith('assets/')
        ? asset.substring('assets/'.length)
        : asset;
    // Use create() (not createFromAsset) because only it forwards audioContext.
    final AudioPool pool = await AudioPool.create(
      source: AssetSource(path),
      maxPlayers: _maxPlayers,
      audioContext: _sfxContext,
      playerMode: PlayerMode.lowLatency,
    );
    _pools.add(pool);
    return _pools.length - 1;
  }

  @override
  Future<void> play(int soundId, {double volume = 1.0}) async {
    if (soundId < 0 || soundId >= _pools.length) {
      return;
    }
    await _pools[soundId].start(volume: volume);
  }

  @override
  Future<void> dispose() async {
    for (final AudioPool pool in _pools) {
      await pool.dispose();
    }
    _pools.clear();
  }
}

/// Plays the press/release click of a [SwitchType] with low latency.
///
/// Construction is cheap; [init] does the work, preloading every clip in
/// [SwitchCatalog] into the injected [SoundBackend] so later [playDown] /
/// [playUp] calls are a single fire-and-forget play. Set [muted] to suppress
/// playback without tearing the player down (e.g. when the user disables
/// sound).
class ClickSoundPlayer {
  ClickSoundPlayer(this._backend);

  final SoundBackend _backend;

  /// Maps an asset path to the sound id returned by the backend at load time.
  final Map<String, int> _soundIds = <String, int>{};

  /// When true, [playDown] / [playUp] become no-ops.
  bool muted = false;

  bool _initialized = false;

  /// Whether [init] has completed and loaded the clips.
  bool get isInitialized => _initialized;

  /// Preloads every down/up clip in [SwitchCatalog.all] into the backend.
  ///
  /// Idempotent: a second call returns immediately. Assets are loaded in the
  /// catalog's order; duplicate paths (should they ever exist) are loaded once.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    for (final SwitchType s in SwitchCatalog.all) {
      for (final String asset in <String>[s.downAsset, s.upAsset]) {
        if (_soundIds.containsKey(asset)) {
          continue;
        }
        _soundIds[asset] = await _backend.load(asset);
      }
    }
    _initialized = true;
  }

  /// Plays [s]'s press clip at [volume]. No-op when [muted] or the clip was
  /// never loaded.
  Future<void> playDown(SwitchType s, {double volume = 1.0}) {
    return _play(s.downAsset, volume);
  }

  /// Plays [s]'s release clip at [volume]. No-op when [muted] or the clip was
  /// never loaded.
  Future<void> playUp(SwitchType s, {double volume = 1.0}) {
    return _play(s.upAsset, volume);
  }

  Future<void> _play(String asset, double volume) async {
    if (muted) {
      return;
    }
    final int? soundId = _soundIds[asset];
    if (soundId == null) {
      return;
    }
    await _backend.play(soundId, volume: volume);
  }

  /// Releases the backend and clears the loaded-clip table.
  Future<void> dispose() async {
    _soundIds.clear();
    _initialized = false;
    await _backend.dispose();
  }
}

/// App-wide click-sound player, backed by [AudioPlayersBackend].
///
/// `init()` must be awaited during app startup (in `main`) before the first
/// click. Tests override this with a player wrapping a fake backend.
final Provider<ClickSoundPlayer> clickSoundPlayerProvider =
    Provider<ClickSoundPlayer>((Ref ref) {
      final AudioPlayersBackend backend = AudioPlayersBackend();
      final ClickSoundPlayer player = ClickSoundPlayer(backend);
      ref.onDispose(player.dispose);
      return player;
    });
