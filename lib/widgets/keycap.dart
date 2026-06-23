import 'package:cliker/providers/settings_providers.dart';
import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/led_ripple.dart';
import 'package:flutter/material.dart';

/// The large, central, pressable *mechanical switch + keycap* that is the face
/// of the app.
///
/// [Keycap] renders a realistic stack, bottom to top:
///
/// - **Plate**: a dark rounded base from which the LED [ledColor] *underglow*
///   leaks out around the switch.
/// - **Switch housing**: a Cherry-MX-style dark-charcoal top housing (with the
///   characteristic stepped notches), and through its center hole the cross
///   ("+") **stem** rises in [stemColor] — the switch's identity.
/// - **Keycap**: a sculpted, glossy OEM-profile cap (dished top + highlight +
///   side walls) seated on the stem, ringed by an [ledColor] rim glow.
///
/// It is deliberately *self-contained*: it knows only about colors, an LED
/// [ledMode], and press callbacks — nothing about audio, haptics, or stats. The
/// [onPressDown] / [onPressUp] callbacks are how a parent wires those in.
///
/// The press reads unmistakably as "the key went down and came back up": while
/// held, the cap (and the stem under it) travels visibly downward (~18 logical
/// px at the default size), the gap between the cap's underside and the housing
/// closes, the cap shrinks slightly, the floor shadow shrinks, and the LED
/// underglow flares. Releasing snaps it all back to rest.
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
    required this.stemColor,
    this.ledMode = LedMode.ripple,
    this.label = '',
    this.onPressDown,
    this.onPressUp,
    this.size = defaultSize,
  });

  /// The base LED color used for the surrounding glow and the press ripples.
  /// In [LedMode.rgbCycle] this is the *starting* hue the cycle sweeps from.
  final Color ledColor;

  /// Color of the switch stem (the cross under the cap) — the switch identity.
  final Color stemColor;

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

  /// Maximum downward travel of the keycap when fully pressed, as a fraction of
  /// [size]. At the default size this is `240 * 0.075 = 18` logical px — well
  /// past the "≥10px so it visibly went down" bar.
  static const double pressTravelFraction = 0.075;

  /// How much the keycap shrinks at full press (uniform scale subtracted).
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

  /// Key on the keycap top face — the sculpted cap whose look changes between
  /// rest and pressed. Tests use it to assert the pressed visual state is
  /// reachable (its [Transform] ancestors shrink on press) and to read the live
  /// glow color/intensity off its first [BoxShadow].
  static const Key innerCapKey = Key('keycap-inner');

  /// Key on the switch layer (plate + housing + stem) [CustomPaint]. Tests read
  /// the painter off it to confirm [stemColor] reached the render.
  static const Key switchLayerKey = Key('keycap-switch-layer');

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
            return _buildStack(context, depth);
          },
        ),
      ),
    );
  }

  /// Builds the full switch+keycap stack for the given press [depth] (0 = rest,
  /// 1 = fully pressed): floor shadow, the underglow plate + switch housing +
  /// stem painted with [KeycapSwitchPainter], the sculpted keycap (which travels
  /// down on press), and any active ripples.
  Widget _buildStack(BuildContext context, double depth) {
    final Color ledColor = _effectiveLedColor();
    final double glow = _glowIntensity();
    final double size = widget.size;

    // The keycap travels down and shrinks while held; the gap to the housing
    // closes as it sinks.
    final double travel = size * Keycap.pressTravelFraction * depth;
    final double capScale = 1.0 - Keycap.pressScaleDrop * depth;

    // Floor shadow shrinks toward the base as the cap sinks (less air gap).
    final double shadowScale = 1.0 - 0.45 * depth;
    final double shadowOpacity = 0.55 * (1.0 - 0.7 * depth);

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Floor shadow, pinned near the base of the plate; shrinks on press.
        Align(
          alignment: const Alignment(0, 0.94),
          child: Transform.scale(
            scaleX: shadowScale,
            scaleY: shadowScale * 0.5,
            child: Container(
              width: size * 0.8,
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
        // Plate + switch housing + stem + underglow, painted as a unit. The
        // underglow flares with the press depth so the base "lights up".
        Positioned.fill(
          child: CustomPaint(
            key: Keycap.switchLayerKey,
            painter: KeycapSwitchPainter(
              stemColor: widget.stemColor,
              ledColor: ledColor,
              glow: glow,
              depth: depth,
            ),
          ),
        ),
        // The sculpted keycap, seated on the stem. It travels down + shrinks on
        // press. The scale Transform is what observers (and tests) read as the
        // pressed visual state; the resting transform leaves scale at 1.0.
        Transform.translate(
          offset: Offset(0, travel),
          child: Transform.scale(
            scale: capScale,
            child: _buildKeycap(context, ledColor, glow),
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

  /// The sculpted, glossy keycap that sits on the stem: a rounded square with a
  /// dished top, a glossy crown highlight, a darker lower lip (side wall), an
  /// [ledColor] rim glow, and an optional subtle legend.
  ///
  /// The outer [Container] carries [Keycap.innerCapKey] and the LED glow as its
  /// first [BoxShadow] (read by tests for the live glow color/intensity).
  Widget _buildKeycap(BuildContext context, Color ledColor, double glow) {
    final double size = widget.size;
    final double capSize = size * 0.70;
    final double radius = size * 0.16;

    return Container(
      key: Keycap.innerCapKey,
      width: capSize,
      height: capSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Sculpted body: bright crown fading to a darker lower lip / side wall.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.keycapTop,
            AppColors.keycapBase,
            AppColors.keycapEdge,
          ],
          stops: <double>[0.0, 0.66, 1.0],
        ),
        border: Border.all(color: AppColors.keycapEdge, width: 2),
        boxShadow: <BoxShadow>[
          // The LED rim glow — first shadow; stronger/tighter while
          // pressed/flaring. (Tests read this first shadow.)
          BoxShadow(
            color: ledColor.withValues(alpha: glow),
            blurRadius: 22 + 18 * glow,
            spreadRadius: 1 + 4 * glow,
          ),
          // A subtle drop under the cap so it reads as raised off the housing.
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          children: <Widget>[
            // Dished center: a radial well, darker in the middle, catching a
            // ring of the LED color — the OEM "scoop".
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius * 0.7),
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: <Color>[
                      AppColors.keycapEdge.withValues(alpha: 0.55),
                      AppColors.keycapBase.withValues(alpha: 0.0),
                      ledColor.withValues(alpha: 0.10 + 0.20 * glow),
                    ],
                    stops: const <double>[0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Glossy crown highlight: a soft white sheen on the upper third,
            // giving the cap its plastic-gloss read.
            Positioned(
              left: capSize * 0.10,
              right: capSize * 0.10,
              top: capSize * 0.04,
              height: capSize * 0.30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius * 0.6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.textPrimary.withValues(alpha: 0.16),
                      AppColors.textPrimary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Optional subtle legend (form-first; very faint).
            if (widget.label.isNotEmpty)
              Center(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.85),
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
          ],
        ),
      ),
    );
  }
}

/// Paints the plate, the Cherry-MX-style switch housing, the cross stem, and the
/// LED underglow leaking out from under the switch — everything *below* the
/// keycap. Driven by the press [depth] so the underglow flares as the key sinks.
class KeycapSwitchPainter extends CustomPainter {
  const KeycapSwitchPainter({
    required this.stemColor,
    required this.ledColor,
    required this.glow,
    required this.depth,
  });

  /// Color of the cross stem (switch identity).
  final Color stemColor;

  /// Current effective LED color (already hue-cycled if applicable).
  final Color ledColor;

  /// Glow intensity in [0, 1].
  final double glow;

  /// Press depth in [0, 1]; brightens the underglow as the key sinks.
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset center = size.center(Offset.zero);

    // Geometry: the plate fills most of the box; the housing is centered and a
    // bit smaller; the stem cross is centered in the housing.
    final double plateSide = s * 0.92;
    final double housingSide = s * 0.62;
    final Rect plateRect = Rect.fromCenter(
      center: center,
      width: plateSide,
      height: plateSide,
    );
    final Rect housingRect = Rect.fromCenter(
      center: center,
      width: housingSide,
      height: housingSide,
    );

    // 1) LED underglow: a soft radial bloom under the switch that intensifies
    // with the press. Drawn first so the plate/housing sit on top of it.
    final double underAlpha = (0.35 + 0.45 * depth).clamp(0.0, 1.0) * glow;
    final Paint underglow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          ledColor.withValues(alpha: underAlpha),
          ledColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: plateSide * 0.62));
    canvas.drawCircle(center, plateSide * 0.62, underglow);

    // 2) Plate: dark rounded base.
    final RRect plate = RRect.fromRectAndRadius(
      plateRect,
      Radius.circular(s * 0.16),
    );
    final Paint platePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[AppColors.surfaceHi, AppColors.bg],
      ).createShader(plateRect);
    canvas.drawRRect(plate, platePaint);
    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.keycapEdge,
    );

    // A thin ring of LED color leaking from the seam between plate and housing.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        housingRect.inflate(s * 0.03),
        Radius.circular(s * 0.10),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 4 * depth
        ..color = ledColor.withValues(alpha: (0.25 + 0.4 * depth) * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3) Switch housing: dark charcoal Cherry-MX top housing with stepped
    // corner notches and a lighter top bevel.
    const Color housingColor = Color(0xFF2A2A33);
    final RRect housing = RRect.fromRectAndRadius(
      housingRect,
      Radius.circular(s * 0.06),
    );
    canvas.drawRRect(
      housing,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[housingColor, Color(0xFF1C1C24)],
        ).createShader(housingRect),
    );
    // Top bevel highlight (the MX housing's lit upper edge).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          housingRect.left,
          housingRect.top,
          housingRect.width,
          housingRect.height * 0.18,
        ),
        Radius.circular(s * 0.06),
      ),
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.05),
    );
    // Characteristic stepped notches: small squares at each housing corner.
    final double notch = housingSide * 0.16;
    final Paint notchPaint = Paint()..color = const Color(0xFF14141A);
    for (final Offset corner in <Offset>[
      housingRect.topLeft,
      housingRect.topRight,
      housingRect.bottomLeft,
      housingRect.bottomRight,
    ]) {
      final double nx = corner.dx < center.dx ? corner.dx : corner.dx - notch;
      final double ny = corner.dy < center.dy ? corner.dy : corner.dy - notch;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(nx, ny, notch, notch),
          Radius.circular(s * 0.015),
        ),
        notchPaint,
      );
    }

    // 4) The cross "+" stem in stemColor, rising from the housing center. A
    // recessed dark well sits behind it so the stem reads as inset.
    final double wellR = housingSide * 0.30;
    canvas.drawCircle(center, wellR, Paint()..color = const Color(0xFF101016));
    final double armLong = housingSide * 0.42;
    final double armShort = housingSide * 0.12;
    final Paint stemPaint = Paint()..color = stemColor;
    final Paint stemHi = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.18);
    // Horizontal then vertical arm → a plus sign.
    final RRect hArm = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: armLong, height: armShort),
      Radius.circular(armShort * 0.3),
    );
    final RRect vArm = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: armShort, height: armLong),
      Radius.circular(armShort * 0.3),
    );
    canvas.drawRRect(hArm, stemPaint);
    canvas.drawRRect(vArm, stemPaint);
    // A small top-left highlight on the stem for a molded-plastic read.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -armShort * 0.18),
          width: armLong * 0.9,
          height: armShort * 0.4,
        ),
        Radius.circular(armShort * 0.2),
      ),
      stemHi,
    );
  }

  @override
  bool shouldRepaint(KeycapSwitchPainter oldDelegate) {
    return oldDelegate.stemColor != stemColor ||
        oldDelegate.ledColor != ledColor ||
        oldDelegate.glow != glow ||
        oldDelegate.depth != depth;
  }
}

/// One active press ripple, tracked so it can be removed by [id] on completion.
@immutable
class _RippleEntry {
  const _RippleEntry({required this.id, required this.color});

  final int id;
  final Color color;
}
