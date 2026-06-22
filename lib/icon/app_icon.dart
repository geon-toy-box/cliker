import 'package:cliker/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Renders the cliker launcher-icon artwork — a single neon-RGB-lit mechanical
/// keycap on the app's dark background — entirely from code, with no external
/// design assets.
///
/// The painting is fully deterministic: every color, gradient, and offset is a
/// pure function of the canvas size, so rendering the same [AppIcon] at the same
/// size always produces identical pixels. That is what lets the icon-generation
/// test commit a stable 1024×1024 PNG and re-derive it byte-for-byte.
///
/// Two presentations share one painter:
///
/// - [AppIcon] (the default) paints the dark [AppColors.bg] field plus the
///   keycap, suitable as the *legacy* square launcher icon (`image_path`).
/// - [AppIcon.foreground] paints only the keycap on a transparent canvas, kept
///   inside the adaptive-icon safe zone, for use as the adaptive
///   `adaptive_icon_foreground` layer over a solid background color.
class AppIcon extends StatelessWidget {
  /// The full icon: dark background field + centered neon keycap.
  const AppIcon({super.key, this.size = defaultSize})
    : _transparentBackground = false;

  /// The adaptive-icon foreground: the keycap only, on a transparent canvas,
  /// scaled to sit inside the adaptive safe zone so launcher masking never clips
  /// it. Layered over [backgroundColor] (or an [AppColors.bg] background image)
  /// by the adaptive icon.
  const AppIcon.foreground({super.key, this.size = defaultSize})
    : _transparentBackground = true;

  /// Edge length of the square icon, in logical pixels. Defaults to the
  /// 1024×1024 master size expected by `flutter_launcher_icons`.
  final double size;

  /// Whether the background field is omitted (transparent) — true for the
  /// adaptive foreground layer, false for the full legacy icon.
  final bool _transparentBackground;

  /// Master icon edge length used for the committed PNG source.
  static const double defaultSize = 1024;

  /// Solid background color for the adaptive icon's background layer. Matches
  /// the app's [AppColors.bg] so the icon reads as one dark surface.
  static const Color backgroundColor = AppColors.bg;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppIconPainter(transparentBackground: _transparentBackground),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

/// Paints the cliker keycap artwork. Stateless and deterministic: identical
/// inputs (canvas [Size] + [transparentBackground]) yield identical pixels.
class _AppIconPainter extends CustomPainter {
  const _AppIconPainter({required this.transparentBackground});

  /// When true, the dark background field is skipped and the keycap is scaled
  /// down into the adaptive safe zone (foreground layer); when false the full
  /// legacy icon (background + keycap) is drawn.
  final bool transparentBackground;

  /// Neon LED colors swept across the keycap glow, in canonical palette order.
  static const List<Color> _neon = AppColors.ledPalette;

  @override
  void paint(Canvas canvas, Size size) {
    final double edge = size.shortestSide;
    final Offset center = Offset(size.width / 2, size.height / 2);

    if (!transparentBackground) {
      _paintBackground(canvas, size, edge);
    }

    // The keycap occupies most of a full icon, but is shrunk into the central
    // safe zone for the adaptive foreground so launcher masks never clip it.
    final double capExtent = edge * (transparentBackground ? 0.56 : 0.66);
    final Rect capRect = Rect.fromCenter(
      center: center,
      width: capExtent,
      height: capExtent,
    );
    final double radius = capExtent * 0.22;
    final RRect capRRect = RRect.fromRectAndRadius(
      capRect,
      Radius.circular(radius),
    );

    _paintGlow(canvas, capRect, radius, edge);
    _paintCapBody(canvas, capRRect, capRect);
    _paintTopFace(canvas, capRRect, capRect, radius);
    _paintGlyph(canvas, capRect);
  }

  /// Dark radial field, slightly lifted at the center so the keycap reads as
  /// emerging from the background.
  void _paintBackground(Canvas canvas, Size size, double edge) {
    final Rect full = Offset.zero & size;
    final Paint bg = Paint()
      ..shader = const RadialGradient(
        radius: 0.75,
        colors: <Color>[AppColors.surface, AppColors.bg],
      ).createShader(full);
    canvas.drawRect(full, bg);
  }

  /// Neon-RGB halo behind the cap. Built from layered translucent radial
  /// gradients rather than [MaskFilter.blur] — the gradients give the same soft
  /// glow but render quickly and identically under the headless software
  /// renderer (a large-radius blur filter is pathologically slow there), keeping
  /// generation fast and reproducible.
  void _paintGlow(Canvas canvas, Rect capRect, double radius, double edge) {
    final Offset center = capRect.center;

    // Outer RGB sweep — the full neon palette ringing the cap, faded out at the
    // rim by a radial alpha so it reads as a soft halo.
    final double sweepRadius = capRect.width * 0.95;
    final Rect sweepBounds = Rect.fromCircle(
      center: center,
      radius: sweepRadius,
    );
    final Paint sweep = Paint()
      ..blendMode = BlendMode.plus
      ..shader = SweepGradient(
        colors: <Color>[..._neon, _neon.first],
        transform: const GradientRotation(-1.2),
      ).createShader(sweepBounds);
    canvas.drawCircle(center, sweepRadius, sweep);

    // Radial fade applied over the sweep: opaque background near the rim, clear
    // at the center, so the sweep only shows as an outer ring.
    final Paint fade = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.bg.withValues(alpha: 0.0),
          AppColors.bg.withValues(alpha: 0.0),
          AppColors.bg,
        ],
        stops: const <double>[0.0, 0.62, 1.0],
      ).createShader(sweepBounds);
    canvas.drawCircle(center, sweepRadius, fade);

    // Tight cyan core glow hugging the cap edge — a soft radial bloom.
    final double coreRadius = capRect.width * 0.72;
    final Paint core = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.neonCyan.withValues(alpha: 0.55),
          AppColors.neonCyan.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, core);
  }

  /// The beveled cap body: a vertical gradient from a lighter top to a darker
  /// edge, with a crisp dark border — the same shading idiom as the in-app
  /// [AppColors] keycap tokens.
  void _paintCapBody(Canvas canvas, RRect capRRect, Rect capRect) {
    final Paint body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppColors.keycapTop,
          AppColors.keycapBase,
          AppColors.keycapEdge,
        ],
        stops: <double>[0.0, 0.7, 1.0],
      ).createShader(capRect);
    canvas.drawRRect(capRRect, body);

    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = capRect.width * 0.012
      ..color = AppColors.keycapEdge;
    canvas.drawRRect(capRRect, border);
  }

  /// Recessed top face that catches the cyan LED faintly, giving the cap depth.
  void _paintTopFace(
    Canvas canvas,
    RRect capRRect,
    Rect capRect,
    double radius,
  ) {
    final Rect faceRect = capRect.deflate(capRect.width * 0.12);
    final RRect faceRRect = RRect.fromRectAndRadius(
      faceRect,
      Radius.circular(radius * 0.7),
    );
    final Paint face = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.neonCyan.withValues(alpha: 0.22),
          AppColors.keycapBase.withValues(alpha: 0.0),
        ],
      ).createShader(faceRect);
    canvas.drawRRect(faceRRect, face);
  }

  /// The centered glyph: a bold "C" (cliker) drawn as a vector arc rather than
  /// laid-out text, so it is font-independent and renders identically in the
  /// headless test environment and on-device. A neon-cyan glow trails the
  /// stroke, then a bright white stroke sits on top.
  void _paintGlyph(Canvas canvas, Rect capRect) {
    final Offset center = capRect.center;
    final double glyphRadius = capRect.width * 0.26;
    final double strokeWidth = capRect.width * 0.11;

    // A "C": an arc swept around the glyph circle leaving a gap on the right.
    final Rect arcRect = Rect.fromCircle(center: center, radius: glyphRadius);
    const double startAngle = 0.62; // radians; opens toward the right.
    const double sweepAngle = 6.283185307179586 - 1.24; // 2π minus the gap.
    final Path cPath = Path()..addArc(arcRect, startAngle, sweepAngle);

    // Neon-cyan glow behind the stroke: a wider, translucent stroke (no blur
    // filter — see _paintGlow — so software rendering stays fast).
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.9
      ..strokeCap = StrokeCap.round
      ..color = AppColors.neonCyan.withValues(alpha: 0.45)
      ..blendMode = BlendMode.plus;
    canvas.drawPath(cPath, glow);

    // Crisp white "C" on top.
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.textPrimary;
    canvas.drawPath(cPath, stroke);
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) =>
      oldDelegate.transparentBackground != transparentBackground;
}
