import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Renders an animated hourglass whose sand level in the top/bottom bulbs
/// reflects [fraction] (1.0 = full/just started, 0.0 = empty/time's up),
/// plus a trickling stream and small pile growth in the bottom bulb, and
/// falling grain particles for extra realism while [isRunning] is true.
class HourglassWidget extends StatefulWidget {
  final double fraction; // remaining time fraction, 0..1
  final bool isRunning;
  final double size;

  const HourglassWidget({
    super.key,
    required this.fraction,
    required this.isRunning,
    this.size = 220,
  });

  @override
  State<HourglassWidget> createState() => _HourglassWidgetState();
}

class _HourglassWidgetState extends State<HourglassWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _HourglassPainter(
            fraction: widget.fraction,
            isRunning: widget.isRunning,
            particlePhase: _particleController.value,
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double fraction;
  final bool isRunning;
  final double particlePhase;

  _HourglassPainter({
    required this.fraction,
    required this.isRunning,
    required this.particlePhase,
  });

  static const frameColor = Color(0xFF8D6E63); // warm wood frame
  static const glassStroke = Color(0xFFB0BEC5);
  static const sandColor = Color(0xFFE0A458);
  static const sandColorDark = Color(0xFFD1893B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final topFrameY = h * 0.08;
    final neckY = h * 0.5;
    final bottomFrameY = h * 0.92;
    final bulbHalfWidth = w * 0.36;
    final neckHalfWidth = w * 0.035;

    // ---- Glass bulb outline (two mirrored trapezoids meeting at neck) ----
    final glassPath = Path()
      ..moveTo(cx - bulbHalfWidth, topFrameY)
      ..lineTo(cx + bulbHalfWidth, topFrameY)
      ..quadraticBezierTo(cx + bulbHalfWidth * 0.9, neckY - h * 0.08, cx + neckHalfWidth, neckY)
      ..quadraticBezierTo(cx + bulbHalfWidth * 0.9, neckY + h * 0.08, cx + bulbHalfWidth, bottomFrameY)
      ..lineTo(cx - bulbHalfWidth, bottomFrameY)
      ..quadraticBezierTo(cx - bulbHalfWidth * 0.9, neckY + h * 0.08, cx - neckHalfWidth, neckY)
      ..quadraticBezierTo(cx - bulbHalfWidth * 0.9, neckY - h * 0.08, cx - bulbHalfWidth, topFrameY)
      ..close();

    canvas.save();
    canvas.clipPath(glassPath);

    // ---- Upper sand pile (shrinks as fraction decreases) ----
    if (fraction > 0.01) {
      final upperSandTopY = lerpDouble(neckY - h * 0.02, topFrameY, fraction)!;
      final upperSandPath = Path()
        ..moveTo(cx - bulbHalfWidth, upperSandTopY)
        ..lineTo(cx + bulbHalfWidth, upperSandTopY)
        ..lineTo(cx + neckHalfWidth * 1.4, neckY - h * 0.015)
        ..lineTo(cx - neckHalfWidth * 1.4, neckY - h * 0.015)
        ..close();
      canvas.drawPath(
        upperSandPath,
        Paint()..color = sandColor,
      );
    }

    // ---- Falling stream through the neck ----
    if (isRunning && fraction > 0.01 && fraction < 0.995) {
      final streamPaint = Paint()..color = sandColor.withValues(alpha: 0.9);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, neckY), width: neckHalfWidth * 1.1, height: h * 0.1),
        streamPaint,
      );
      // A couple of individually falling grains for texture.
      final rnd = Random(1);
      for (int i = 0; i < 4; i++) {
        final t = ((particlePhase + i * 0.27) % 1.0);
        final gy = neckY - h * 0.05 + t * h * 0.14;
        final gx = cx + (rnd.nextDouble() - 0.5) * neckHalfWidth;
        canvas.drawCircle(Offset(gx, gy), 1.4, Paint()..color = sandColorDark);
      }
    }

    // ---- Lower sand pile (grows as fraction decreases) ----
    final lowerFraction = 1 - fraction;
    if (lowerFraction > 0.01) {
      final pileHeight = (bottomFrameY - neckY - h * 0.02) * lowerFraction;
      final pileTopY = bottomFrameY - pileHeight;
      final spread = lerpDouble(neckHalfWidth * 1.4, bulbHalfWidth, lowerFraction)!;
      final lowerSandPath = Path()
        ..moveTo(cx - spread, pileTopY)
        ..quadraticBezierTo(cx, pileTopY - h * 0.02, cx + spread, pileTopY)
        ..lineTo(cx + bulbHalfWidth, bottomFrameY)
        ..lineTo(cx - bulbHalfWidth, bottomFrameY)
        ..close();
      canvas.drawPath(lowerSandPath, Paint()..color = sandColor);
    }

    canvas.restore();

    // ---- Glass outline stroke ----
    canvas.drawPath(
      glassPath,
      Paint()
        ..color = glassStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // subtle glass highlight
    canvas.drawLine(
      Offset(cx - bulbHalfWidth * 0.55, topFrameY + h * 0.06),
      Offset(cx - bulbHalfWidth * 0.55, neckY - h * 0.08),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ---- Wooden top/bottom caps + side posts ----
    final capPaint = Paint()..color = frameColor;
    final capHeight = h * 0.06;
    RRect topCap = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bulbHalfWidth * 1.15, topFrameY - capHeight, bulbHalfWidth * 2.3, capHeight),
      const Radius.circular(6),
    );
    RRect bottomCap = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bulbHalfWidth * 1.15, bottomFrameY, bulbHalfWidth * 2.3, capHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(topCap, capPaint);
    canvas.drawRRect(bottomCap, capPaint);
    canvas.drawRect(
      Rect.fromLTWH(cx - bulbHalfWidth * 1.15, topFrameY - capHeight / 2, w * 0.04, bottomFrameY - topFrameY + capHeight),
      capPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + bulbHalfWidth * 1.15 - w * 0.04, topFrameY - capHeight / 2, w * 0.04, bottomFrameY - topFrameY + capHeight),
      capPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.particlePhase != particlePhase;
  }
}
