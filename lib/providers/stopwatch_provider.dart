import 'dart:async';
import 'package:flutter/foundation.dart';

class StopwatchProvider extends ChangeNotifier {
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = [];

  bool get isRunning => _sw.isRunning;
  Duration get elapsed => _sw.elapsed;
  List<Duration> get laps => List.unmodifiable(_laps);

  void start() {
    _sw.start();
    // Tick every 30ms for a smooth centisecond/millisecond LCD readout.
    _ticker ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _sw.stop();
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void lap() {
    if (_sw.isRunning) {
      _laps.insert(0, _sw.elapsed);
      notifyListeners();
    }
  }

  void reset() {
    _sw.reset();
    _laps.clear();
    if (!_sw.isRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
    notifyListeners();
  }

  /// Formats elapsed time as MM:SS.CC (centiseconds) for the LCD display.
  String get formatted {
    final d = elapsed;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centis';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
