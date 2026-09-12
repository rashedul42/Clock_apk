import 'package:flutter/material.dart';

class TimerPreset {
  final String label;
  final Duration duration;
  final IconData icon;

  const TimerPreset({
    required this.label,
    required this.duration,
    required this.icon,
  });

  static const List<TimerPreset> defaults = [
    TimerPreset(label: 'Meeting', duration: Duration(minutes: 30), icon: Icons.groups_rounded),
    TimerPreset(label: 'Sleep', duration: Duration(hours: 8), icon: Icons.bedtime_rounded),
    TimerPreset(label: 'Exercise', duration: Duration(minutes: 20), icon: Icons.fitness_center_rounded),
    TimerPreset(label: 'Mindfulness', duration: Duration(minutes: 10), icon: Icons.self_improvement_rounded),
    TimerPreset(label: 'Work', duration: Duration(minutes: 45), icon: Icons.work_rounded),
  ];
}
