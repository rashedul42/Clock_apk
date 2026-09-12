import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../models/alarm_task.dart';
import '../../../theme/app_theme.dart';
import 'task_base.dart';

/// Task 2: Fitness. Counts push-ups or squats.
///
/// [FitnessDetectionMode.accelerometer]: phone is placed on the floor
/// (push-ups) or in a pocket/held (squats); each rep produces a
/// characteristic accelerometer dip-then-spike on the vertical axis, which
/// we detect via simple peak detection with a refractory period so a
/// single rep can't be double-counted.
///
/// [FitnessDetectionMode.camera]: stubbed here as an integration point —
/// swap `_CameraRepCounter` for a pose-estimation package (e.g. google_ml_kit
/// pose detection) to count reps from the live camera feed instead.
class FitnessTask extends StatefulWidget {
  final FitnessExercise exercise;
  final int repsRequired;
  final FitnessDetectionMode detectionMode;
  final TaskCompletedCallback onCompleted;

  const FitnessTask({
    super.key,
    required this.exercise,
    required this.repsRequired,
    required this.detectionMode,
    required this.onCompleted,
  });

  @override
  State<FitnessTask> createState() => _FitnessTaskState();
}

class _FitnessTaskState extends State<FitnessTask> {
  int _reps = 0;
  StreamSubscription<AccelerometerEvent>? _sub;

  // Simple peak-detector state.
  double _lastMagnitude = 9.8;
  bool _inDip = false;
  DateTime _lastRepAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (widget.detectionMode == FitnessDetectionMode.accelerometer) {
      _listenAccelerometer();
    }
  }

  void _listenAccelerometer() {
    _sub = accelerometerEventStream().listen((event) {
      final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
      final gSquared = magnitude; // ~96 (9.8^2) at rest
      const restG2 = 96.0;

      // Detect a dip below rest (going down) followed by a spike above rest
      // (pushing back up) as one rep, with a 600ms refractory window.
      if (!_inDip && gSquared < restG2 * 0.75) {
        _inDip = true;
      } else if (_inDip && gSquared > restG2 * 1.35) {
        final now = DateTime.now();
        if (now.difference(_lastRepAt) > const Duration(milliseconds: 600)) {
          _lastRepAt = now;
          _inDip = false;
          if (mounted) {
            setState(() {
              _reps++;
              if (_reps >= widget.repsRequired) {
                widget.onCompleted();
              }
            });
          }
        }
      }
      _lastMagnitude = gSquared;
    });
  }

  /// Manual increment — exposed as a fallback button in case sensor
  /// detection misfires, and used for the camera-mode stub below.
  void _manualIncrement() {
    setState(() {
      _reps++;
      if (_reps >= widget.repsRequired) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.exercise == FitnessExercise.pushups ? 'Push-ups' : 'Squats';
    return TaskScaffold(
      emoji: '🏋️',
      title: '$exerciseName to Dismiss',
      instructions: widget.detectionMode == FitnessDetectionMode.accelerometer
          ? 'Place your phone nearby and perform each rep steadily — motion is detected automatically'
          : 'Position your phone so the camera can see your full body',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TaskProgressPill(current: _reps, total: widget.repsRequired),
          const SizedBox(height: 32),
          _RepDial(reps: _reps, total: widget.repsRequired),
          const SizedBox(height: 32),
          if (widget.detectionMode == FitnessDetectionMode.camera)
            _CameraRepCounterStub(onManualRep: _manualIncrement)
          else
            TextButton(
              onPressed: _manualIncrement,
              child: const Text(
                "Sensor not detecting? Tap to count a rep manually",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _RepDial extends StatelessWidget {
  final int reps;
  final int total;
  const _RepDial({required this.reps, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (reps / total).clamp(0.0, 1.0);
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          Text('$reps', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Placeholder for camera-based pose counting. Wire a pose-estimation
/// model here (see class doc) and call [onManualRep] each time a rep is
/// recognized instead of exposing a manual button to the end user.
class _CameraRepCounterStub extends StatelessWidget {
  final VoidCallback onManualRep;
  const _CameraRepCounterStub({required this.onManualRep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Camera preview\n(pose-detection rep counter)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onManualRep,
          child: const Text('Simulate rep detected', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
