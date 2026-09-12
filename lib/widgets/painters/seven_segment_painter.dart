import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Segment map for characters 0-9, ':' and '.' — each entry is
/// [top, topRight, bottomRight, bottom, bottomLeft, topLeft, middle].
const Map<String, List<bool>> _segmentMap = {
  '0': [true, true, true, true, true, true, false],
  '1': [false, true, true, false, false, false, false],
  '2': [true, true, false, true, true, false, true],
  '3': [true, true, true, true, false, false, true],
  '4': [false, true, true, false, false, true, true],
  '5': [true, false, true, true, false, true, true],
  '6': [true, false, true, true, true, true, true],
  '7': [true, true, true, false, false, false, false],
  '8': [true, true, true, true, true, true, true],
  '9': [true, true, true, true, false, true, true],
  ' ': [false, false, false, false, false, false, false],
};

/// Draws one retro 7-segment "LCD" digit. Unlit segments render as a faint
/// ghost (matching a real LCD panel where inactive segments are still
/// faintly visible), lit segments glow in phosphor green.
class SevenSegmentDigit extends StatelessWidget {
  final String char; // single digit 0-9 or ' '
  final double height;

  const SevenSegmentDigit({super.key, required this.char, this.height = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.55,
      height: height,
      child: CustomPaint(
        painter: _SegmentPainter(char: char),
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  final String char;
  _SegmentPainter({required this.char});

  @override
  void paint(Canvas canvas, Size size) {
    final segs = _segmentMap[char] ?? _segmentMap[' ']!;
    final w = size.width;
    final h = size.height;
    final thickness = w * 0.16;

    final onPaint = Paint()
      ..color = AppColors.lcdDigitOn
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    final offPaint = Paint()
      ..color = AppColors.lcdDigitOff
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Segment geometry as horizontal/vertical rounded bars.
    void hBar(double cy, bool on) {
      final rect = Rect.fromCenter(
        center: Offset(w / 2, cy),
        width: w - thickness,
        height: thickness,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
        on ? onPaint : offPaint,
      );
    }

    void vBar(double cx, double cyStart, double cyEnd, bool on) {
      final rect = Rect.fromLTRB(cx - thickness / 2, cyStart, cx + thickness / 2, cyEnd);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
        on ? onPaint : offPaint,
      );
    }

    final midY = h / 2;
    // top
    hBar(thickness / 2, segs[0]);
    // topRight
    vBar(w - thickness / 2, thickness, midY - thickness / 4, segs[1]);
    // bottomRight
    vBar(w - thickness / 2, midY + thickness / 4, h - thickness, segs[2]);
    // bottom
    hBar(h - thickness / 2, segs[3]);
    // bottomLeft
    vBar(thickness / 2, midY + thickness / 4, h - thickness, segs[4]);
    // topLeft
    vBar(thickness / 2, thickness, midY - thickness / 4, segs[5]);
    // middle
    hBar(midY, segs[6]);
  }

  @override
  bool shouldRepaint(covariant _SegmentPainter oldDelegate) => oldDelegate.char != char;
}

/// Full retro LCD panel: renders a time string like "05:23.41" as a row
/// of 7-segment digits with ':' / '.' separators, on a recessed green
/// LCD-style background panel.
class LcdPanel extends StatelessWidget {
  final String text;
  final double digitHeight;

  const LcdPanel({super.key, required this.text, this.digitHeight = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.lcdBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final ch in text.split(''))
            if (ch == ':' || ch == '.')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Separator(char: ch, height: digitHeight),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SevenSegmentDigit(char: ch, height: digitHeight),
              ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  final String char;
  final double height;
  const _Separator({required this.char, required this.height});

  @override
  Widget build(BuildContext context) {
    if (char == '.') {
      return SizedBox(
        width: height * 0.14,
        height: height,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: height * 0.12,
            height: height * 0.12,
            margin: EdgeInsets.only(bottom: height * 0.04),
            decoration: const BoxDecoration(
              color: AppColors.lcdDigitOn,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    // colon
    final dot = height * 0.1;
    return SizedBox(
      width: height * 0.18,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: dot, height: dot, decoration: const BoxDecoration(color: AppColors.lcdDigitOn, shape: BoxShape.circle)),
          SizedBox(height: height * 0.18),
          Container(width: dot, height: dot, decoration: const BoxDecoration(color: AppColors.lcdDigitOn, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
