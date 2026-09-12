import 'package:flutter/material.dart';
import 'alarm_task.dart';

/// Days of week bitmask helper — Mon=0 .. Sun=6, matching a 7-item bool list.
class Alarm {
  final String id;
  final TimeOfDay time;
  final List<bool> repeatDays; // length 7, Mon..Sun
  final String label;
  final String soundName;
  final int snoozeMinutes; // 0 = snooze disabled
  final bool vibrate;
  final bool deleteAfterRinging;
  final bool enabled;
  final AlarmTaskConfig taskConfig;

  const Alarm({
    required this.id,
    required this.time,
    this.repeatDays = const [false, false, false, false, false, false, false],
    this.label = '',
    this.soundName = 'Default Chime',
    this.snoozeMinutes = 10,
    this.vibrate = true,
    this.deleteAfterRinging = false,
    this.enabled = true,
    this.taskConfig = const AlarmTaskConfig(),
  });

  bool get isRepeating => repeatDays.any((d) => d);

  String get repeatSummary {
    if (!isRepeating) return 'Once';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdays = repeatDays.sublist(0, 5).every((d) => d) &&
        !repeatDays[5] &&
        !repeatDays[6];
    if (weekdays) return 'Weekdays';
    if (repeatDays.every((d) => d)) return 'Every day';
    return [
      for (int i = 0; i < 7; i++)
        if (repeatDays[i]) names[i]
    ].join(', ');
  }

  Alarm copyWith({
    TimeOfDay? time,
    List<bool>? repeatDays,
    String? label,
    String? soundName,
    int? snoozeMinutes,
    bool? vibrate,
    bool? deleteAfterRinging,
    bool? enabled,
    AlarmTaskConfig? taskConfig,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      label: label ?? this.label,
      soundName: soundName ?? this.soundName,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      vibrate: vibrate ?? this.vibrate,
      deleteAfterRinging: deleteAfterRinging ?? this.deleteAfterRinging,
      enabled: enabled ?? this.enabled,
      taskConfig: taskConfig ?? this.taskConfig,
    );
  }
}
