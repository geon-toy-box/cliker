import 'dart:math' as math;

import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A self-contained circular hue picker — a conic "RGB disc" with a draggable
/// thumb that sits on the selected hue.
///
/// [RgbWheel] is deliberately dependency-free: there is no third-party color
/// picker. The ring is painted with [CustomPaint] (a sweep-gradient annulus)
/// and the thumb is positioned at the angle of the current [color]. Tapping or
/// dragging anywhere reports a new color via [onColorChanged].
///
/// Only the *hue* is chosen here; saturation and value are held at full (vivid
/// LED colors), matching the gaming-keyboard look. The angle→hue mapping is
/// exposed as the static [hueAt] / [colorForHue] so it can be unit-tested
/// independently of the widget tree.
///
/// Angle convention: hue 0° (red) is at the top of the wheel (12 o'clock) and
/// increases clockwise, so the painted ring and the thumb agree with the HSV
/// hue the callback emits.
class RgbWheel extends StatefulWidget {
  const RgbWheel({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.size = defaultSize,
  });

  /// The currently selected color. Its HSV hue places the thumb; saturation and
  /// value are ignored for placement (the wheel only picks hue).
  final Color color;

  /// Called on every tap/drag with the freshly picked, fully-saturated color.
  final ValueChanged<Color> onColorChanged;

  /// Diameter of the wheel, in logical pixels.
  final double size;

  /// Default wheel diameter.
  static const double defaultSize = 220;

  /// Fraction of the radius taken up by the colored ring (the hollow center is
  /// the remaining inner disc). 0.30 → a chunky, easy-to-hit ring.
  static const double ringFraction = 0.30;

  /// Key on the gesture surface, so tests/callers can find the wheel.
  static const Key wheelKey = Key('rgb-wheel');

  /// The hue, in degrees [0, 360), for a touch at [local] within a box of
  /// [size] × [size]. 0° is at the top and hue increases clockwise.
  ///
  /// Pure and static so the coordinate→hue mapping is unit-testable without a
  /// widget. A touch exactly at the center is ambiguous and returns 0°.
  static double hueAt(Offset local, double size) {
    final double cx = size / 2;
    final double cy = size / 2;
    final double dx = local.dx - cx;
    final double dy = local.dy - cy;
    if (dx == 0 && dy == 0) {
      return 0;
    }
    // atan2 with these arguments yields 0 at the top and grows clockwise:
    //   top  (dx=0, dy<0) → 0°
    //   right(dx>0, dy=0) → 90°
    //   bottom            → 180°
    //   left              → 270°
    final double radians = math.atan2(dx, -dy);
    final double degrees = radians * 180.0 / math.pi;
    return (degrees + 360.0) % 360.0;
  }

  /// The fully-saturated, full-value [Color] for [hue] degrees. This is the
  /// exact color the callback emits and the ring paints, so picker and preview
  /// always agree.
  static Color colorForHue(double hue) {
    return HSVColor.fromAHSV(1.0, hue % 360.0, 1.0, 1.0).toColor();
  }

  @override
  State<RgbWheel> createState() => _RgbWheelState();
}

class _RgbWheelState extends State<RgbWheel> {
  /// Maps a local touch to a hue, emits the matching color, unless the touch is
  /// dead-center (no meaningful angle).
  void _emitFor(Offset local) {
    final double hue = RgbWheel.hueAt(local, widget.size);
    widget.onColorChanged(RgbWheel.colorForHue(hue));
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    // The current hue places the thumb; full S/V isn't needed for placement.
    final double hue = HSVColor.fromColor(widget.color).hue;

    return GestureDetector(
      key: RgbWheel.wheelKey,
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails d) => _emitFor(d.localPosition),
      onPanStart: (DragStartDetails d) => _emitFor(d.localPosition),
      onPanUpdate: (DragUpdateDetails d) => _emitFor(d.localPosition),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _WheelPainter(
            hue: hue,
            ringFraction: RgbWheel.ringFraction,
            selectedColor: RgbWheel.colorForHue(hue),
          ),
        ),
      ),
    );
  }
}

/// Paints the conic hue ring, a soft inner glow in the selected color, and the
/// draggable thumb sitting on the current hue.
class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.hue,
    required this.ringFraction,
    required this.selectedColor,
  });

  /// Current hue in degrees; positions the thumb.
  final double hue;

  /// Ring thickness as a fraction of the radius.
  final double ringFraction;

  /// The fully-saturated color for [hue]; used for the thumb + center glow.
  final Color selectedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double outerRadius = size.shortestSide / 2;
    final double ringWidth = outerRadius * ringFraction;
    final double ringCenterRadius = outerRadius - ringWidth / 2;

    // The conic rainbow. Stops match hueAt: 0° at the top, clockwise. Using HSV
    // samples every 60° keeps the gradient true to the colors the wheel emits.
    final List<Color> sweepColors = <Color>[
      for (int deg = 0; deg <= 360; deg += 60)
        RgbWheel.colorForHue(deg.toDouble()),
    ];
    final List<double> sweepStops = <double>[
      for (int i = 0; i < sweepColors.length; i++) i / (sweepColors.length - 1),
    ];

    // SweepGradient starts at 3 o'clock and goes clockwise by default; rotate
    // it by -90° so hue 0° lands at the top, matching hueAt's convention.
    final Gradient ringGradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: sweepColors,
      stops: sweepStops,
      transform: const GradientRotation(-math.pi / 2),
    );

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..shader = ringGradient.createShader(
        Rect.fromCircle(center: center, radius: ringCenterRadius),
      );
    canvas.drawCircle(center, ringCenterRadius, ringPaint);

    // Inner disc: dark surface with a soft glow of the selected color so the
    // center previews the live pick.
    final double innerRadius = outerRadius - ringWidth;
    final Paint innerFill = Paint()..color = AppColors.surface;
    canvas.drawCircle(center, innerRadius, innerFill);
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          selectedColor.withValues(alpha: 0.45),
          selectedColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawCircle(center, innerRadius, glow);

    // The thumb: a white-ringed dot filled with the selected color, sitting on
    // the ring at the current hue. Angle mirrors hueAt (0° at top, clockwise).
    final double thumbAngle = (hue % 360.0) * math.pi / 180.0;
    final Offset thumbCenter = Offset(
      center.dx + ringCenterRadius * math.sin(thumbAngle),
      center.dy - ringCenterRadius * math.cos(thumbAngle),
    );
    final double thumbRadius = ringWidth * 0.62;
    canvas.drawCircle(
      thumbCenter,
      thumbRadius + 3,
      Paint()..color = AppColors.textPrimary,
    );
    canvas.drawCircle(thumbCenter, thumbRadius, Paint()..color = selectedColor);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.ringFraction != ringFraction ||
        oldDelegate.selectedColor != selectedColor;
  }
}
