import 'dart:math';
import 'package:flutter/material.dart';

/// Detailed Big Ben-style clock tower illustration with a live analog face
/// whose hands rotate to reflect [time] (the selected world-clock city time).
class BigBenTower extends StatelessWidget {
  final DateTime time;
  final double width;
  final double height;

  const BigBenTower({super.key, required this.time, this.width = 260, this.height = 260});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BigBenPainter(time: time),
    );
  }
}

class _BigBenPainter extends CustomPainter {
  final DateTime time;
  _BigBenPainter({required this.time});

  static const stoneLight = Color(0xFFE7DFC9);
  static const stoneMid = Color(0xFFD3C7A0);
  static const stoneDark = Color(0xFFB5A672);
  static const goldAccent = Color(0xFFC9A227);
  static const faceCream = Color(0xFFF5EFD9);
  static const skyBlueSoft = Color(0xFFDDEBF7);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ---- Soft sky backdrop ----
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = skyBlueSoft.withValues(alpha: 0.35),
    );

    final towerWidth = w * 0.5;
    final towerLeft = cx - towerWidth / 2;
    final towerTop = h * 0.06;
    final baseY = h * 0.98;

    // ---- Tower shaft with vertical gothic detailing ----
    final shaftPaint = Paint()..color = stoneLight;
    final shaftRect = Rect.fromLTRB(towerLeft, towerTop + h * 0.22, towerLeft + towerWidth, baseY);
    canvas.drawRect(shaftRect, shaftPaint);

    // shading stripes down the shaft
    final stripePaint = Paint()..color = stoneMid.withValues(alpha: 0.5);
    for (int i = 1; i < 5; i++) {
      final x = towerLeft + towerWidth * i / 5;
      canvas.drawRect(Rect.fromLTWH(x - 1.2, towerTop + h * 0.22, 2.4, baseY - (towerTop + h * 0.22)), stripePaint);
    }

    // corner turrets (small spires flanking the main tower)
    void turret(double dx) {
      final tx = cx + dx;
      final turretPath = Path()
        ..moveTo(tx - w * 0.035, towerTop + h * 0.22)
        ..lineTo(tx - w * 0.035, towerTop + h * 0.1)
        ..lineTo(tx, towerTop + h * 0.02)
        ..lineTo(tx + w * 0.035, towerTop + h * 0.1)
        ..lineTo(tx + w * 0.035, towerTop + h * 0.22)
        ..close();
      canvas.drawPath(turretPath, Paint()..color = stoneDark);
    }

    turret(-towerWidth * 0.55);
    turret(towerWidth * 0.55);

    // ---- Clock housing (square block behind the round face) ----
    final houseSize = towerWidth * 1.06;
    final houseTop = towerTop + h * 0.2;
    final houseRect = Rect.fromLTWH(cx - houseSize / 2, houseTop, houseSize, houseSize * 0.62);
    canvas.drawRect(houseRect, Paint()..color = stoneMid);
    canvas.drawRect(
      houseRect,
      Paint()
        ..color = goldAccent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ---- Gothic spire above the clock housing ----
    final spirePath = Path()
      ..moveTo(towerLeft - w * 0.02, towerTop + h * 0.22)
      ..lineTo(cx, 0)
      ..lineTo(towerLeft + towerWidth + w * 0.02, towerTop + h * 0.22)
      ..close();
    canvas.drawPath(spirePath, Paint()..color = stoneDark);
    // spire highlight line
    canvas.drawLine(Offset(cx, 0), Offset(cx, towerTop + h * 0.22), Paint()..color = goldAccent..strokeWidth = 1.5);
    // finial ball + cross
    canvas.drawCircle(Offset(cx, h * 0.01), 3, Paint()..color = goldAccent);
    canvas.drawLine(Offset(cx, h * 0.01 - 10), Offset(cx, h * 0.01), Paint()..color = goldAccent..strokeWidth = 2);
    canvas.drawLine(Offset(cx - 4, h * 0.01 - 6), Offset(cx + 4, h * 0.01 - 6), Paint()..color = goldAccent..strokeWidth = 2);

    // ---- Clock face ----
    final faceCenter = Offset(cx, houseTop + houseSize * 0.31);
    final faceRadius = houseSize * 0.27;
    canvas.drawCircle(faceCenter, faceRadius + 6, Paint()..color = goldAccent);
    canvas.drawCircle(faceCenter, faceRadius, Paint()..color = faceCream);
    canvas.drawCircle(
      faceCenter,
      faceRadius,
      Paint()
        ..color = const Color(0xFF3E3423)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Roman-numeral-style tick marks (simplified as bold ticks)
    final tickPaint = Paint()..color = const Color(0xFF3E3423)..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final outer = faceCenter + Offset(faceRadius * 0.9 * sin(angle), -faceRadius * 0.9 * cos(angle));
      final inner = faceCenter + Offset(faceRadius * 0.72 * sin(angle), -faceRadius * 0.72 * cos(angle));
      canvas.drawLine(inner, outer, tickPaint..strokeWidth = 2.4);
    }

    // ---- Live analog hands reflecting `time` ----
    final minute = time.minute + time.second / 60.0;
    final hour = (time.hour % 12) + minute / 60.0;
    final minuteAngle = (minute / 60) * 2 * pi;
    final hourAngle = (hour / 12) * 2 * pi;

    void hand(double angle, double length, double strokeWidth) {
      final end = faceCenter + Offset(length * sin(angle), -length * cos(angle));
      canvas.drawLine(
        faceCenter,
        end,
        Paint()
          ..color = const Color(0xFF2B2418)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    hand(hourAngle, faceRadius * 0.5, 3.4);
    hand(minuteAngle, faceRadius * 0.72, 2.4);
    canvas.drawCircle(faceCenter, 2.6, Paint()..color = goldAccent);

    // ---- Lower tower body with arched windows ----
    final windowPaint = Paint()..color = const Color(0xFF7C8B94).withValues(alpha: 0.55);
    for (int i = 0; i < 2; i++) {
      final wy = houseTop + houseSize * 0.75 + i * h * 0.16;
      final windowRect = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(cx, wy), width: towerWidth * 0.32, height: h * 0.09),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      );
      canvas.drawRRect(windowRect, windowPaint);
    }

    // ---- Base plinth ----
    canvas.drawRect(Rect.fromLTWH(towerLeft - w * 0.03, baseY, towerWidth + w * 0.06, h * 0.02), Paint()..color = stoneDark);
  }

  @override
  bool shouldRepaint(covariant _BigBenPainter oldDelegate) => oldDelegate.time != time;
}
