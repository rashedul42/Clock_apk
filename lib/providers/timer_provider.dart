import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerProvider extends ChangeNotifier {
  Duration _totalDuration = const Duration(minutes: 10);
  Duration _remaining = const Duration(minutes: 10);
  Timer? _ticker;
  bool _isRunning = false;

  Duration get totalDuration => _totalDuration;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;
  bool get isFinished => _remaining <= Duration.zero;

  /// 1.0 = full (sand all in upper bulb), 0.0 = empty (all sand dropped).
  /// Drives the hourglass CustomPainter's sand-level animation.
  double get remainingFraction {
    if (_totalDuration.inMilliseconds == 0) return 0;
    return (_remaining.inMilliseconds / _totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void setDuration(Duration d) {
    _totalDuration = d;
    _remaining = d;
    notifyListeners();
  }

  void start() {
    if (_remaining <= Duration.zero) return;
    _isRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _remaining -= const Duration(milliseconds: 200);
      if (_remaining <= Duration.zero) {
        _remaining = Duration.zero;
        _isRunning = false;
        _ticker?.cancel();
        // TODO: trigger AlarmProvider-style ring screen when timer completes.
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset() {
    _remaining = _totalDuration;
    _isRunning = false;
    _ticker?.cancel();
    notifyListeners();
  }

  String get formatted {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
