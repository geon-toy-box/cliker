import 'package:flutter/material.dart';

/// A single, one-shot LED "burst": a ring that expands outward from the center
/// and fades to nothing, then removes itself.
///
/// [LedRipple] owns its own [AnimationController] and plays exactly once on
/// mount. When the animation completes it invokes [onCompleted], which the
/// parent uses to drop this ripple from the tree — so a press never leaks a
/// lingering animation. The ring is drawn in [color]; nothing about audio,
/// haptics, or keycap state is known here.
class LedRipple extends StatefulWidget {
  const LedRipple({
    super.key,
    required this.color,
    this.onCompleted,
    this.duration = defaultDuration,
  });

  /// Color the expanding ring is painted in (the active LED color).
  final Color color;

  /// Called once, after the ripple's animation finishes, so the owner can
  /// remove this widget from the tree.
  final VoidCallback? onCompleted;

  /// How long the expand-and-fade animation runs.
  final Duration duration;

  /// Default ripple lifetime. Exposed so callers (and tests) can pump exactly
  /// this much time to drive the ripple to completion.
  static const Duration defaultDuration = Duration(milliseconds: 450);

  @override
  State<LedRipple> createState() => _LedRippleState();
}

class _LedRippleState extends State<LedRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _RipplePainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

/// Paints the expanding, fading ring for a [LedRipple].
///
/// [progress] runs 0 → 1: the ring grows from a small radius to fill its box
/// while its opacity and stroke width ease down to zero.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.progress, required this.color});

  /// Animation progress in the range [0, 1].
  final double progress;

  /// Ring color before the progress-driven opacity is applied.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxRadius = size.shortestSide / 2;

    // Decelerating expansion so the ring shoots out then settles.
    final double eased = Curves.easeOut.transform(progress);
    final double radius = maxRadius * (0.2 + 0.8 * eased);

    // Fade the whole ring out across the animation; thin the stroke as it grows.
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);
    final double strokeWidth = 6.0 * (1.0 - 0.7 * progress);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: opacity);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
