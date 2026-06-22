import 'package:cliker/theme/app_colors.dart';
import 'package:cliker/theme/app_spacing.dart';
import 'package:cliker/widgets/led_ripple.dart';
import 'package:flutter/material.dart';

/// The large, central, pressable mechanical-keycap that is the face of the app.
///
/// [Keycap] is deliberately *self-contained*: it knows only about colors and
/// press callbacks. It renders a 3D-ish cap (beveled base + gradient top +
/// center label) wrapped in an [ledColor] glow, plays a fast press-down /
/// snap-up animation, intensifies the glow while held, and fires one
/// [LedRipple] per press. It knows nothing about audio, haptics, or stats —
/// the [onPressDown] / [onPressUp] callbacks are how a parent wires those in.
///
/// Each press calls [onPressDown] exactly once (on `onTapDown`) and [onPressUp]
/// exactly once (on `onTapUp` *or* `onTapCancel`, so a press is always balanced
/// by a release).
class Keycap extends StatefulWidget {
  const Keycap({
    super.key,
    required this.ledColor,
    this.label = '',
    this.onPressDown,
    this.onPressUp,
    this.size = defaultSize,
  });

  /// The solid LED color used for the surrounding glow and the press ripples.
  final Color ledColor;

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

  /// Key on the inner cap container, whose look changes between rest and
  /// pressed. Tests use it to assert the pressed visual state is reachable.
  static const Key innerCapKey = Key('keycap-inner');

  @override
  State<Keycap> createState() => _KeycapState();
}

class _KeycapState extends State<Keycap> with SingleTickerProviderStateMixin {
  /// Drives press depth: 0 = fully at rest, 1 = fully pressed.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: Keycap.pressDownDuration,
    reverseDuration: Keycap.pressUpDuration,
  );

  /// Active ripples, keyed so each can remove exactly itself on completion.
  final List<_RippleEntry> _ripples = <_RippleEntry>[];
  int _rippleSeq = 0;

  /// Whether the cap is currently held down. Exposed for the pressed visual.
  bool _isPressed = false;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _press.forward();
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
      _ripples.add(_RippleEntry(id: id, color: widget.ledColor));
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
          animation: _press,
          builder: (BuildContext context, Widget? child) {
            // Eased press depth in [0, 1].
            final double depth = Curves.easeOut.transform(_press.value);
            // Cap shrinks slightly and sinks a few pixels while held.
            final double scale = 1.0 - 0.06 * depth;
            final double travel = AppSpacing.sm * depth;

            return Transform.translate(
              offset: Offset(0, travel),
              child: Transform.scale(scale: scale, child: child),
            );
          },
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
      ),
    );
  }

  /// Builds the static cap visual (glow + beveled body + label). The press
  /// transform and ripples are applied by the caller.
  Widget _buildCap(BuildContext context) {
    final double glow = 0.45 + 0.55 * Curves.easeOut.transform(_press.value);
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
          // The LED glow — stronger and tighter while pressed.
          BoxShadow(
            color: widget.ledColor.withValues(alpha: glow),
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
                        widget.ledColor.withValues(alpha: 0.10 + 0.18 * glow),
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
                        color: widget.ledColor.withValues(alpha: glow),
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
