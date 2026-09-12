import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../models/alarm.dart';
import '../../models/alarm_task.dart';
import '../../providers/alarm_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/painters/twin_bell_painter.dart';
import 'dismissal_tasks/math_task.dart';
import 'dismissal_tasks/exercise_task.dart';
import 'dismissal_tasks/photo_task.dart';
import 'dismissal_tasks/qr_scan_task.dart';
import 'dismissal_tasks/reading_task.dart';

/// Maps an alarm's human-readable sound name (chosen in AddAlarmScreen) to
/// its asset file under assets/sounds/. Drop matching mp3 files there —
/// see assets/sounds/README.md.
String _soundAssetFor(String soundName) {
  final slug = soundName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return 'sounds/$slug.mp3';
}

/// The "Alarm Challenge Screen". Mounted full-screen (see main.dart's
/// navigator listener) whenever AlarmProvider.ringingAlarm is non-null.
///
/// CORE INVARIANT of the Task-Based Alarm Dismissal System:
/// there is exactly one call site for AlarmProvider.dismiss() in this
/// whole screen — [_handleTaskCompleted] — and it is only reachable from
/// a task widget's onCompleted callback (or, when the alarm has no task
/// configured, from the plain slide-to-dismiss control). No back button,
/// no system-back gesture, and no other affordance on this screen can
/// silence the alarm; PopScope below blocks navigation away from it.
///
/// This widget also owns the ringtone loop (audioplayers) and vibration
/// pattern (vibration) for as long as it's mounted, starting them in
/// initState and tearing them down in dispose — so leaving this screen
/// (only possible via dismiss/snooze) always cleanly stops both.
class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingForAlarmId;

  Future<void> _ensureAudioAndVibration(Alarm alarm) async {
    if (_playingForAlarmId == alarm.id) return; // already ringing for this alarm
    _playingForAlarmId = alarm.id;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(_soundAssetFor(alarm.soundName)));
    } catch (_) {
      // Missing/placeholder sound asset — ringing continues silently rather
      // than crashing; drop real mp3 files in assets/sounds/ to fix.
    }

    if (alarm.vibrate) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(pattern: const [500, 1000], repeat: 0);
      }
    }
  }

  Future<void> _stopAudioAndVibration() async {
    _playingForAlarmId = null;
    await _player.stop();
    Vibration.cancel();
  }

  @override
  void dispose() {
    _player.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarmProvider = context.watch<AlarmProvider>();
    final alarm = alarmProvider.ringingAlarm;

    if (alarm == null) {
      // Should never be visible without a ringing alarm, but guard anyway.
      _stopAudioAndVibration();
      return const SizedBox.shrink();
    }

    // Fire-and-forget: safe to call every build, it no-ops once already
    // playing for this alarm id.
    _ensureAudioAndVibration(alarm);

    return PopScope(
      canPop: false, // Cannot back-out of an alarm without completing the task.
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1B2F),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Text(
                  alarm.label.isEmpty ? 'Alarm' : alarm.label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                TwinBellClock(time: alarm.time, ringing: true, size: 130),
                const SizedBox(height: 8),
                Expanded(
                  child: _TaskRouter(
                    alarm: alarm,
                    onTaskCompleted: () => _handleTaskCompleted(context),
                  ),
                ),
                if (alarm.snoozeMinutes > 0 && alarm.taskConfig.hasTask)
                  TextButton(
                    onPressed: () async {
                      await _stopAudioAndVibration();
                      if (context.mounted) context.read<AlarmProvider>().snooze();
                    },
                    child: Text(
                      'Snooze ${alarm.snoozeMinutes} min (task still required after)',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTaskCompleted(BuildContext context) {
    // The single choke point: only reached after a task widget (or the
    // no-task slide control) reports genuine success.
    _stopAudioAndVibration();
    context.read<AlarmProvider>().dismiss();
  }
}

/// Picks which task widget to mount based on the alarm's AlarmTaskConfig.
class _TaskRouter extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onTaskCompleted;

  const _TaskRouter({required this.alarm, required this.onTaskCompleted});

  @override
  Widget build(BuildContext context) {
    final config = alarm.taskConfig;

    if (!config.hasTask) {
      return _NoTaskDismiss(onDismiss: onTaskCompleted);
    }

    switch (config.taskType!) {
      case AlarmTaskType.math:
        return MathTask(
          problemCount: config.mathProblemCount,
          difficulty: config.mathDifficulty,
          onCompleted: onTaskCompleted,
        );
      case AlarmTaskType.fitness:
        return FitnessTask(
          exercise: config.exercise,
          repsRequired: config.repsRequired,
          detectionMode: config.detectionMode,
          onCompleted: onTaskCompleted,
        );
      case AlarmTaskType.imageRecognition:
        return ImageRecognitionTask(
          targetLabel: config.targetObjectLabel,
          onCompleted: onTaskCompleted,
        );
      case AlarmTaskType.qrScan:
        return QrScanTask(
          expectedPayload: config.qrPayload ?? '',
          onCompleted: onTaskCompleted,
        );
      case AlarmTaskType.speechReading:
        return SpeechReadingTask(
          phrase: config.readingPhrase,
          onCompleted: onTaskCompleted,
        );
    }
  }
}

/// Fallback control when no dismissal task is configured for the alarm —
/// a deliberate slide gesture (not a single tap) to avoid accidental dismissal.
class _NoTaskDismiss extends StatefulWidget {
  final VoidCallback onDismiss;
  const _NoTaskDismiss({required this.onDismiss});

  @override
  State<_NoTaskDismiss> createState() => _NoTaskDismissState();
}

class _NoTaskDismissState extends State<_NoTaskDismiss> {
  double _dragX = 0;
  static const _trackWidth = 260.0;
  static const _thumbSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm, color: Colors.white70, size: 56),
          const SizedBox(height: 24),
          Container(
            width: _trackWidth,
            height: _thumbSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_thumbSize / 2),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Text('Slide to dismiss', style: TextStyle(color: Colors.white54)),
                ),
                AnimatedPositioned(
                  duration: _dragX == 0 ? const Duration(milliseconds: 200) : Duration.zero,
                  left: _dragX,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragX = (_dragX + details.delta.dx).clamp(0.0, _trackWidth - _thumbSize);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (_dragX > _trackWidth - _thumbSize - 10) {
                        widget.onDismiss();
                      } else {
                        setState(() => _dragX = 0);
                      }
                    },
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
