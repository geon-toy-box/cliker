import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/led_ripple.dart';
import 'package:flutter/material.dart';

/// The large, central, pressable mechanical-keycap that is the face of the app.
///
/// [Keycap] is deliberately *self-contained*: it knows only about colors, an
/// LED [ledMode], and press callbacks. It renders a 3D-ish cap (beveled base +
/// gradient top + center label) wrapped in an [ledColor] glow, plays a fast
/// press-down / snap-up animation, intensifies the glow while held, and fires
/// one [LedRipple] per press. It knows nothing about audio, haptics, or stats —
/// the [onPressDown] / [onPressUp] callbacks are how a parent wires those in.
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
  static const Duration pressUpDuration = Duration(milliseconds: 90);

  /// Lifetime of a single press ripple; re-exported from [LedRipple] so callers
  /// and tests have one place to read the value.
  static const Duration rippleDuration = LedRipple.defaultDuration;

  /// Full period of one [LedMode.rgbCycle] hue sweep (0° → 360°). Exposed so
  /// tests can pump a known fraction and assert the hue moved.
  static const Duration rgbCycleDuration = Duration(seconds: 6);

  /// How long a [LedMode.reactive] press flare takes to decay back to its dim
  /// baseline after release. Exposed for the same reason as [rgbCycleDuration].
  static const Duration reactiveDecayDuration = Duration(milliseconds: 1200);

  /// Key on the inner cap container, whose look changes between rest and
  /// pressed. Tests use it to assert the pressed visual state is reachable and
  /// to read the live glow color/intensity off its [BoxShadow].
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
            // Cap shrinks slightly and sinks a few pixels while held.
            final double scale = 1.0 - 0.06 * depth;
            final double travel = AppSpacing.sm * depth;

            return Transform.translate(
              offset: Offset(0, travel),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    _buildCap(context),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the static cap visual (glow + beveled body + label). The press
  /// transform and ripples are applied by the caller. Reads the live
  /// [_effectiveLedColor] and [_glowIntensity] so the mode animations show.
  Widget _buildCap(BuildContext context) {
    final Color ledColor = _effectiveLedColor();
    final double glow = _glowIntensity();
    final double radius = widget.size * 0.16;

    return Container(
      key: Keycap.innerCapKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Beveled body: lighter top edge, darker bottom edge.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.keycapTop,
            AppColors.keycapBase,
            AppColors.keycapEdge,
          ],
          stops: <double>[0.0, 0.7, 1.0],
        ),
        border: Border.all(color: AppColors.keycapEdge, width: 2),
        boxShadow: <BoxShadow>[
          // The LED glow — stronger and tighter while pressed / flaring.
          BoxShadow(
            color: ledColor.withValues(alpha: glow),
            blurRadius: 24 + 16 * glow,
            spreadRadius: 1 + 3 * glow,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Recessed top face that catches the LED color faintly.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius * 0.7),
                    gradient: RadialGradient(
                      colors: <Color>[
                        ledColor.withValues(alpha: 0.10 + 0.18 * glow),
                        AppColors.keycapBase.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.label.isNotEmpty)
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: widget.size * 0.22,
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
            ],
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
