import 'dart:math';
import 'package:flutter/material.dart';

/// Classic red twin-bell alarm clock illustration. The analog hour/minute
/// hands rotate to match [time], and while [ringing] is true the bells
/// wiggle and little "clang" motion lines are drawn (driven by an internal
/// looping animation).
class TwinBellClock extends StatefulWidget {
  final TimeOfDay time;
  final bool ringing;
  final double size;

  const TwinBellClock({
    super.key,
    required this.time,
    this.ringing = false,
    this.size = 220,
  });

  @override
  State<TwinBellClock> createState() => _TwinBellClockState();
}

class _TwinBellClockState extends State<TwinBellClock> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _TwinBellPainter(
            time: widget.time,
            ringing: widget.ringing,
            wigglePhase: _controller.value,
          ),
        );
      },
    );
  }
}

class _TwinBellPainter extends CustomPainter {
  final TimeOfDay time;
  final bool ringing;
  final double wigglePhase; // 0..1, ping-ponged

  _TwinBellPainter({required this.time, required this.ringing, required this.wigglePhase});

  static const bodyRed = Color(0xFFE53935);
  static const bodyRedDark = Color(0xFFC62828);
  static const metalGrey = Color(0xFFCFD8DC);
  static const faceWhite = Color(0xFFFFFDF7);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.56;
    final radius = min(w, h) * 0.34;

    final wiggle = ringing ? (sin(wigglePhase * 2 * pi) * 6 * pi / 180) : 0.0;

    // ---- Feet ----
    final feetPaint = Paint()..color = bodyRedDark;
    canvas.drawCircle(Offset(cx - radius * 0.55, cy + radius * 1.05), radius * 0.09, feetPaint);
    canvas.drawCircle(Offset(cx + radius * 0.55, cy + radius * 1.05), radius * 0.09, feetPaint);

    // ---- Bells (left & right), rotated slightly when ringing ----
    void drawBell(double sign) {
      canvas.save();
      final bellCenter = Offset(cx + sign * radius * 0.92, cy - radius * 0.78);
      canvas.translate(bellCenter.dx, bellCenter.dy);
      canvas.rotate(sign * wiggle);
      final bellPaint = Paint()..color = bodyRed;
      canvas.drawArc(
        Rect.fromCenter(center: Offset.zero, width: radius * 0.95, height: radius * 0.95),
        pi,
        pi,
        true,
        bellPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(0, radius * 0.02), width: radius * 0.95, height: radius * 0.08),
        bellPaint,
      );
      // bell knob
      canvas.drawCircle(Offset(0, -radius * 0.5), radius * 0.07, Paint()..color = metalGrey);
      canvas.restore();
    }

    drawBell(-1);
    drawBell(1);

    // ---- Center hammer/handle between bells ----
    final handlePaint = Paint()
      ..color = metalGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - radius * 1.15), width: radius * 0.5, height: radius * 0.4),
      pi * 1.1,
      pi * 0.8,
      false,
      handlePaint,
    );

    // ---- Main clock body (red circle with metal bezel) ----
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = bodyRed);
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = bodyRedDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.05,
    );

    // ---- Side bell buttons (small metal domes on either side) ----
    canvas.drawCircle(Offset(cx - radius * 1.02, cy), radius * 0.1, Paint()..color = metalGrey);
    canvas.drawCircle(Offset(cx + radius * 1.02, cy), radius * 0.1, Paint()..color = metalGrey);

    // ---- White clock face ----
    final faceRadius = radius * 0.78;
    canvas.drawCircle(Offset(cx, cy), faceRadius, Paint()..color = faceWhite);

    // ---- Hour tick marks ----
    final tickPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final outer = Offset(cx + faceRadius * 0.92 * sin(angle), cy - faceRadius * 0.92 * cos(angle));
      final inner = Offset(
        cx + faceRadius * (i % 3 == 0 ? 0.75 : 0.82) * sin(angle),
        cy - faceRadius * (i % 3 == 0 ? 0.75 : 0.82) * cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint..strokeWidth = i % 3 == 0 ? 3 : 1.8);
    }

    // ---- Hands: dynamically point to `time` ----
    final minuteAngle = (time.minute / 60) * 2 * pi;
    final hourAngle = ((time.hourOfPeriod % 12) / 12) * 2 * pi + (time.minute / 60) * (2 * pi / 12);

    void drawHand(double angle, double length, double strokeWidth, Color color) {
      final end = Offset(cx + length * sin(angle), cy - length * cos(angle));
      canvas.drawLine(
        Offset(cx, cy),
        end,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    drawHand(hourAngle, faceRadius * 0.48, 4.2, const Color(0xFF3E2723));
    drawHand(minuteAngle, faceRadius * 0.68, 3, const Color(0xFF3E2723));

    // center pin
    canvas.drawCircle(Offset(cx, cy), 3.5, Paint()..color = bodyRed);

    // ---- Motion "clang" lines when ringing ----
    if (ringing) {
      final motionPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (final sign in [-1, 1]) {
        final bx = cx + sign * radius * 1.35;
        for (int i = 0; i < 3; i++) {
          final yy = cy - radius * 0.9 + i * 10;
          canvas.drawLine(Offset(bx, yy), Offset(bx + sign * 8, yy), motionPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TwinBellPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.ringing != ringing ||
        oldDelegate.wigglePhase != wigglePhase;
  }
}
