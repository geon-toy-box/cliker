import 'dart:async';

import 'package:cliker/audio/click_sound_player.dart';
import 'package:cliker/domain/switch_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turns one screen press into the perceptual "딸깍 ↔ 따~알~깍" gradient.
///
/// A real key actuation is not one sound but a short *sequence* of events along
/// the stem's travel: a soft pre-travel **onset** ("따"), the actuation
/// **click** ("알" — the click-jacket snap of a clicky switch, a softer bump for
/// a tactile one, and *nothing* for a pure linear), then the **bottom-out**
/// thud ("깍"). Press fast and they collapse into a single crisp "딸깍"; press
/// slowly/softly and they spread out in time into "따~알~깍".
///
/// A touchscreen only gives us *down* and *up*, so this engine models the
/// downstroke as time after [pressDown]: the click and bottom-out are
/// *scheduled* to fire at delays that widen with how drawn-out the press should
/// be ([spreadFor]). The user's own release timing then decides the character,
/// which makes the whole feature work on every platform (no pressure sensor
/// required):
///
/// - **Quick stab** — released before the actuation click even fires: the
///   pending events are cancelled and the tight combined [ClickSoundPlayer.playDown]
///   clip plays instead, so every fast tap is a satisfying crisp "딸깍".
/// - **Medium press** — released after the click but before bottom-out: you
///   heard onset + click, and no bottom-out thud follows (just like releasing a
///   real key before it bottoms) → "따알".
/// - **Full press** — held past bottom-out: onset → click → bottom all sound in
///   sequence → the drawn-out "따~알~깍".
///
/// Where the platform reports a real touch [force] (e.g. force-touch screens) it
/// *modulates* the feel — a firm press tightens the spread and plays louder, a
/// soft press widens it and plays quieter — but force is never required; the
/// [intensity] setting (the "강도" slider) scales the spread on its own.
///
/// The engine is sound-only and self-contained: it holds the in-flight timers
/// and the per-press state, and defers all playback to [ClickSoundPlayer]
/// (which already no-ops when muted). The owner must call [pressUp] for every
/// [pressDown] so the schedule is always balanced; [dispose] cancels any
/// in-flight timers.
class DynamicClickEngine {
  DynamicClickEngine(this._player);

  final ClickSoundPlayer _player;

  // ── Tunables (exposed for tests and on-device feel tuning) ───────────────
  //
  // Delays are measured from [pressDown]. The *min* end is the snappy extreme
  // (firm / high spread is tight); the *max* end is the drawn-out extreme.

  /// Actuation-click delay at the snappiest extreme (spread = 0).
  static const Duration clickDelayMin = Duration(milliseconds: 35);

  /// Actuation-click delay at the most drawn-out extreme (spread = 1).
  static const Duration clickDelayMax = Duration(milliseconds: 125);

  /// Bottom-out delay at the snappiest extreme (spread = 0).
  static const Duration bottomDelayMin = Duration(milliseconds: 95);

  /// Bottom-out delay at the most drawn-out extreme (spread = 1).
  static const Duration bottomDelayMax = Duration(milliseconds: 260);

  /// Playback volume of a soft (force ≈ 0) press.
  static const double volumeMin = 0.78;

  /// Playback volume of a firm (force ≈ 1 or unknown) press.
  static const double volumeMax = 1.0;

  // ── Per-press state ──────────────────────────────────────────────────────
  Timer? _clickTimer;
  Timer? _bottomTimer;
  bool _clickFired = false;
  bool _bottomFired = false;
  double _volume = volumeMax;
  SwitchType? _active;

  /// Whether a press is currently in flight (between [pressDown] and [pressUp]).
  ///
  /// The owner uses this to route a release by *who actually started the press*
  /// rather than the live settings flag, so flipping the dynamic-click toggle
  /// mid-press can never strand a schedule (see [pressUp] / [cancel]).
  bool get isPressing => _active != null;

  /// The drawn-out-ness of the decomposition in `[0, 1]` for the given press
  /// [force] (null when unsupported) and [intensity] setting.
  ///
  /// Higher = more spread out (more "따~알~깍"). [intensity] (the 강도 slider)
  /// always contributes; a softer [force] adds spread and a firmer one removes
  /// it, blended 50/50 when force is present.
  static double spreadFor(double? force, double intensity) {
    final double i = intensity.clamp(0.0, 1.0);
    if (force == null) {
      return i;
    }
    final double f = force.clamp(0.0, 1.0);
    return (0.5 * i + 0.5 * (1.0 - f)).clamp(0.0, 1.0);
  }

  /// The actuation-click delay for a press of the given [force]/[intensity].
  static Duration clickDelayFor(double? force, double intensity) =>
      _lerpDuration(clickDelayMin, clickDelayMax, spreadFor(force, intensity));

  /// The bottom-out delay for a press of the given [force]/[intensity].
  static Duration bottomDelayFor(double? force, double intensity) =>
      _lerpDuration(
        bottomDelayMin,
        bottomDelayMax,
        spreadFor(force, intensity),
      );

  /// Playback volume for the given [force]; firm/unknown is loudest, soft is
  /// quietest.
  static double volumeFor(double? force) {
    if (force == null) {
      return volumeMax;
    }
    final double f = force.clamp(0.0, 1.0);
    return volumeMin + (volumeMax - volumeMin) * f;
  }

  /// Begins a press of [s]. Plays the onset immediately and schedules the
  /// actuation click (when [s] has one) and the bottom-out, at delays set by
  /// [force] (null when unsupported) and [intensity].
  void pressDown(SwitchType s, {double? force, double intensity = 0.5}) {
    // Defensive: an unbalanced previous press should never strand timers.
    _cancelTimers();

    _active = s;
    _clickFired = false;
    _bottomFired = false;
    _volume = volumeFor(force);

    // Single source of truth for the delay mapping: the same helpers tests and
    // the settings UI read, so the scheduled timing can never drift from them.
    final Duration clickDelay = clickDelayFor(force, intensity);
    final Duration bottomDelay = bottomDelayFor(force, intensity);

    // "따" — instant, soft contact tick.
    _player.playOnset(s, volume: _volume);

    // "알" — the actuation click (linears have none → skip scheduling it).
    if (s.clickAsset != null) {
      _clickTimer = Timer(clickDelay, () {
        _clickFired = true;
        _player.playClick(s, volume: _volume);
      });
    }
    // "깍" — the bottom-out thud, the deepest point of a full press.
    _bottomTimer = Timer(bottomDelay, () {
      _bottomFired = true;
      _player.playBottom(s, volume: _volume);
    });
  }

  /// Ends the current press. Cancels any not-yet-fired events and plays the
  /// release; on a quick stab (released before the click fired) it also plays
  /// the crisp combined down clip so the tap still lands as a full "딸깍".
  void pressUp() {
    final SwitchType? s = _active;
    if (s == null) {
      return; // No active press — nothing to balance.
    }

    if (!_bottomFired) {
      _bottomTimer?.cancel();
      if (!_clickFired) {
        // Quick stab: nothing but the onset sounded. Cancel the pending click
        // and play the tight combined clip so the tap is a satisfying "딸깍".
        _clickTimer?.cancel();
        _player.playDown(s, volume: _volume);
      }
      // else: the actuation click already sounded but the key was released
      // before bottoming out — no bottom-out thud, just "따알".
    }

    _player.playUp(s, volume: _volume);
    _reset();
  }

  /// Drops any in-flight press: cancels not-yet-fired timers and clears the
  /// active state *without* playing a release. The owner calls this when a press
  /// should be abandoned rather than completed — e.g. when the dynamic-click
  /// toggle is turned off while the classic path takes over.
  void cancel() => _reset();

  /// Cancels any in-flight timers (e.g. on provider disposal).
  void dispose() {
    _cancelTimers();
    _active = null;
  }

  void _cancelTimers() {
    _clickTimer?.cancel();
    _bottomTimer?.cancel();
    _clickTimer = null;
    _bottomTimer = null;
  }

  void _reset() {
    _cancelTimers();
    _clickFired = false;
    _bottomFired = false;
    _active = null;
  }

  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final double clamped = t.clamp(0.0, 1.0);
    final int micros =
        (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * clamped)
            .round();
    return Duration(microseconds: micros);
  }
}

/// App-wide [DynamicClickEngine], driving its playback through the shared
/// [clickSoundPlayerProvider]. Cancels in-flight timers on disposal.
final Provider<DynamicClickEngine> dynamicClickEngineProvider =
    Provider<DynamicClickEngine>((Ref ref) {
      final ClickSoundPlayer player = ref.watch(clickSoundPlayerProvider);
      final DynamicClickEngine engine = DynamicClickEngine(player);
      ref.onDispose(engine.dispose);
      return engine;
    });
