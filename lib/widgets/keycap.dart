import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/led_ripple.dart';
import 'package:flutter/material.dart';

/// The large, central, pressable mechanical-keycap that is the face of the app.
///
/// [Keycap] is deliberately *self-contained*: it knows only about colors, an
/// LED [ledMode], and press callbacks. It renders a sculpted 3D keycap — a
/// rounded, slightly dished top face sitting on a visible side skirt, ringed by
/// an [ledColor] glow and casting a soft floor shadow — plays a *pronounced*
/// press animation, intensifies the glow while held, and fires one [LedRipple]
/// per press. It knows nothing about audio, haptics, or stats — the
/// [onPressDown] / [onPressUp] callbacks are how a parent wires those in.
///
/// The press is meant to read unmistakably as "the key went down and came back
/// up": while held, the top face travels visibly downward (≥10 logical px),
/// shrinks slightly, the skirt compresses so the cap looks shorter, the floor
/// shadow shrinks toward the base, and the LED glow flares. Releasing snaps it
/// all back to rest.
///
/// Each press calls [onPressDown] exactly once (on `onTapDown`) and [onPressUp]
/// exactly once (on `onTapUp` *or* `onTapCancel`, so a press is always balanced
/// by a release).
///
/// The [ledMode] selects how the glow behaves:
///
/// - [LedMode.solid] / [LedMode.ripple]: a steady glow in [ledColor]. (Both
///   modes glow identically; they differ only at the parent level, which uses
///   ripple as the default per-press flourish — every mode still ripples.)
/// - [LedMode.rgbCycle]: the glow (and the press ripples) sweep through hue over
///   time, looping forever, independent of presses.
/// - [LedMode.reactive]: the glow brightens sharply on each press and decays
///   back toward a dim baseline, so the cap "breathes" with recent activity.
class Keycap extends StatefulWidget {
  const Keycap({
    super.key,
    required this.ledColor,
    this.ledMode = LedMode.ripple,
    this.label = '',
    this.onPressDown,
    this.onPressUp,
    this.size = defaultSize,
  });

  /// The base LED color used for the surrounding glow and the press ripples.
  /// In [LedMode.rgbCycle] this is the *starting* hue the cycle sweeps from.
  final Color ledColor;

  /// How the LED glow animates. See the class doc for each mode's behavior.
  final LedMode ledMode;

  /// Text drawn centered on the cap (may be empty).
  final String label;

  /// Called once when a press begins (`onTapDown`).
  final VoidCallback? onPressDown;

  /// Called once when a press ends (`onTapUp` or `onTapCancel`).
  final VoidCallback? onPressUp;

  /// Edge length of the square cap, in logical pixels.
  final double size;

  /// Default cap edge length.
  static const double defaultSize = 240;

  /// Duration of the press-down phase (cap travels down + shrinks).
  static const Duration pressDownDuration = Duration(milliseconds: 60);

  /// Duration of the snap-up phase (cap springs back to rest).
  static const Duration pressUpDuration = Duration(milliseconds: 110);

  /// Maximum downward travel of the top face when fully pressed, as a fraction
  /// of [size]. At the default size this is `240 * 0.075 = 18` logical px — well
  /// past the "≥10px so it visibly went down" bar.
  static const double pressTravelFraction = 0.075;

  /// How much the top face shrinks at full press (uniform scale subtracted).
  static const double pressScaleDrop = 0.07;

  /// Lifetime of a single press ripple; re-exported from [LedRipple] so callers
  /// and tests have one place to read the value.
  static const Duration rippleDuration = LedRipple.defaultDuration;

  /// Full period of one [LedMode.rgbCycle] hue sweep (0° → 360°). Exposed so
  /// tests can pump a known fraction and assert the hue moved.
  static const Duration rgbCycleDuration = Duration(seconds: 6);

  /// How long a [LedMode.reactive] press flare takes to decay back to its dim
  /// baseline after release. Exposed for the same reason as [rgbCycleDuration].
  static const Duration reactiveDecayDuration = Duration(milliseconds: 1200);

  /// Key on the inner cap (top face) container, whose look changes between rest
  /// and pressed. Tests use it to assert the pressed visual state is reachable
  /// and to read the live glow color/intensity off its [BoxShadow].
  static const Key innerCapKey = Key('keycap-inner');

  @override
  State<Keycap> createState() => _KeycapState();
}

class _KeycapState extends State<Keycap> with TickerProviderStateMixin {
  /// Drives press depth: 0 = fully at rest, 1 = fully pressed.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: Keycap.pressDownDuration,
    reverseDuration: Keycap.pressUpDuration,
  );

  /// Loops continuously while in [LedMode.rgbCycle]; its value is the phase of
  /// the hue sweep in [0, 1). Idle (stopped at 0) in every other mode.
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: Keycap.rgbCycleDuration,
  );

  /// Tracks [LedMode.reactive] glow intensity: snapped to 1 on each press, then
  /// allowed to decay back to 0. Idle (at 0) in every other mode.
  late final AnimationController _reactive = AnimationController(
    vsync: this,
    duration: Keycap.reactiveDecayDuration,
  );

  /// Active ripples, keyed so each can remove exactly itself on completion.
  final List<_RippleEntry> _ripples = <_RippleEntry>[];
  int _rippleSeq = 0;

  /// Whether the cap is currently held down. Exposed for the pressed visual.
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _applyMode();
  }

  @override
  void didUpdateWidget(Keycap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ledMode != widget.ledMode) {
      _applyMode();
    }
  }

  /// Starts/stops the per-mode animations so only the controllers a mode needs
  /// are running. Called on mount and whenever [Keycap.ledMode] changes.
  void _applyMode() {
    if (widget.ledMode == LedMode.rgbCycle) {
      _cycle.repeat();
    } else {
      _cycle.stop();
      _cycle.value = 0;
    }
    if (widget.ledMode != LedMode.reactive) {
      _reactive.stop();
      _reactive.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _cycle.dispose();
    _reactive.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _press.forward();
    if (widget.ledMode == LedMode.reactive) {
      // Flare to full intensity, then decay over reactiveDecayDuration.
      _reactive
        ..value = 1.0
        ..reverse(from: 1.0);
    }
    _spawnRipple();
    widget.onPressDown?.call();
  }

  void _handleTapUp(TapUpDetails details) {
    _release();
  }

  void _handleTapCancel() {
    _release();
  }

  void _release() {
    if (!_isPressed) {
      return;
    }
    setState(() => _isPressed = false);
    _press.reverse();
    widget.onPressUp?.call();
  }

  void _spawnRipple() {
    final int id = _rippleSeq++;
    setState(() {
      _ripples.add(_RippleEntry(id: id, color: _effectiveLedColor()));
    });
  }

  void _removeRipple(int id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _ripples.removeWhere((_RippleEntry entry) => entry.id == id);
    });
  }

  /// The LED color currently in effect. In [LedMode.rgbCycle] this is
  /// [Keycap.ledColor] rotated around the HSV hue wheel by the cycle phase; in
  /// every other mode it is simply [Keycap.ledColor].
  Color _effectiveLedColor() {
    if (widget.ledMode != LedMode.rgbCycle) {
      return widget.ledColor;
    }
    final HSVColor base = HSVColor.fromColor(widget.ledColor);
    final double hue = (base.hue + _cycle.value * 360.0) % 360.0;
    // Keep cycling colors vivid even if the base swatch is desaturated.
    return base
        .withHue(hue)
        .withSaturation(base.saturation.clamp(0.7, 1.0))
        .toColor();
  }

  /// Glow intensity in [0, 1] driving the shadow's alpha/blur/spread.
  ///
  /// In [LedMode.reactive] the glow is driven entirely by recent activity: each
  /// press snaps intensity to 1.0, then it eases back toward a dim 0.30 baseline
  /// over [Keycap.reactiveDecayDuration], so a fresh press is markedly brighter
  /// than the cap a moment later (the "breathing with activity" feel).
  ///
  /// In every other mode the static press depth brightens the glow instead
  /// (resting 0.45 → 1.0 while held).
  double _glowIntensity() {
    if (widget.ledMode == LedMode.reactive) {
      return (0.30 + 0.70 * _reactive.value).clamp(0.0, 1.0);
    }
    final double pressGlow = Curves.easeOut.transform(_press.value);
    return (0.45 + 0.55 * pressGlow).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          // Rebuild on any of the three drivers so the glow tracks press,
          // hue-cycle, and reactive decay together.
          animation: Listenable.merge(<Listenable>[_press, _cycle, _reactive]),
          builder: (BuildContext context, Widget? child) {
            // Eased press depth in [0, 1].
            final double depth = Curves.easeOut.transform(_press.value);
            return _buildCap(context, depth);
          },
        ),
      ),
    );
  }

  /// Builds the full sculpted cap for the given press [depth] (0 = rest, 1 =
  /// fully pressed): floor shadow, side skirt, and the dished top face, plus any
  /// active ripples. Reads the live [_effectiveLedColor] and [_glowIntensity] so
  /// the mode animations show.
  Widget _buildCap(BuildContext context, double depth) {
    final Color ledColor = _effectiveLedColor();
    final double glow = _glowIntensity();
    final double size = widget.size;
    final double radius = size * 0.18;

    // Skirt: the visible side wall under the top face. It is tall at rest and
    // compresses as the cap is pressed, so the cap looks physically shorter.
    final double restSkirt = size * 0.16;
    final double skirt = restSkirt * (1.0 - 0.7 * depth);

    // The top face travels down and shrinks while held.
    final double travel = size * Keycap.pressTravelFraction * depth;
    final double topScale = 1.0 - Keycap.pressScaleDrop * depth;

    // Floor shadow shrinks toward the base as the cap sinks (less air gap).
    final double shadowScale = 1.0 - 0.45 * depth;
    final double shadowOpacity = 0.55 * (1.0 - 0.7 * depth);

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Floor shadow, pinned near the base of the cap; shrinks on press.
        Align(
          alignment: const Alignment(0, 0.92),
          child: Transform.scale(
            scaleX: shadowScale,
            scaleY: shadowScale * 0.5,
            child: Container(
              width: size * 0.74,
              height: size * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.08),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
                color: Colors.black.withValues(alpha: shadowOpacity * 0.6),
              ),
            ),
          ),
        ),
        // The side skirt: drawn as a shorter rounded body sitting under the top
        // face, offset down so its lower edge stays put while the top compresses
        // toward it on press.
        Transform.translate(
          offset: Offset(0, skirt * 0.5),
          child: Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppColors.keycapBase, AppColors.keycapEdge],
              ),
              border: Border.all(color: AppColors.keycapEdge, width: 2),
            ),
          ),
        ),
        // The top face: travels down + shrinks on press. The scale Transform is
        // what observers (and tests) read as the pressed visual state.
        Transform.translate(
          offset: Offset(0, travel),
          child: Transform.scale(
            scale: topScale,
            child: _buildTopFace(context, ledColor, glow, radius),
          ),
        ),
        // One LedRipple per active press, sized to the cap.
        for (final _RippleEntry entry in _ripples)
          Positioned.fill(
            key: ValueKey<int>(entry.id),
            child: LedRipple(
              color: entry.color,
              duration: Keycap.rippleDuration,
              onCompleted: () => _removeRipple(entry.id),
            ),
          ),
      ],
    );
  }

  /// The dished top face of the cap: a rounded square with a recessed center
  /// that catches the LED color, the surrounding glow shadow, and the legend.
  ///
  /// The outer [Container] carries [Keycap.innerCapKey] and the LED glow as its
  /// first [BoxShadow] (read by tests for the live glow color/intensity).
  Widget _buildTopFace(
    BuildContext context,
    Color ledColor,
    double glow,
    double radius,
  ) {
    final double topSize = widget.size * 0.78;
    return Container(
      key: Keycap.innerCapKey,
      width: topSize,
      height: topSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Sculpted top: bright crown fading to a darker lower lip.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.keycapTop,
            AppColors.keycapBase,
            AppColors.keycapEdge,
          ],
          stops: <double>[0.0, 0.72, 1.0],
        ),
        border: Border.all(color: AppColors.keycapEdge, width: 2),
        boxShadow: <BoxShadow>[
          // The LED glow — first shadow; stronger/tighter while pressed/flaring.
          BoxShadow(
            color: ledColor.withValues(alpha: glow),
            blurRadius: 24 + 18 * glow,
            spreadRadius: 1 + 4 * glow,
          ),
          // A subtle drop under the top face, so it reads as a raised lid.
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DecoratedBox(
          // Dished center: a radial well that is darker in the middle and
          // catches a ring of the LED color, giving the top a sculpted "scoop".
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius * 0.7),
            gradient: RadialGradient(
              radius: 0.85,
              colors: <Color>[
                AppColors.keycapEdge.withValues(alpha: 0.55),
                AppColors.keycapBase.withValues(alpha: 0.0),
                ledColor.withValues(alpha: 0.12 + 0.20 * glow),
              ],
              stops: const <double>[0.0, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: widget.label.isEmpty
                ? const SizedBox.shrink()
                : Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: widget.size * 0.16,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      shadows: <Shadow>[
                        Shadow(
                          color: ledColor.withValues(alpha: glow),
                          blurRadius: 12 * glow,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// One active press ripple, tracked so it can be removed by [id] on completion.
@immutable
class _RippleEntry {
  const _RippleEntry({required this.id, required this.color});

  final int id;
  final Color color;
}
