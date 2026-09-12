import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alarm.dart';

/// Owns the alarm list plus the "currently ringing" state, which is the
/// entry point into the Task-Based Alarm Dismissal System: while
/// [ringingAlarm] is non-null, the UI is forced to AlarmRingScreen, and
/// [dismiss] can only be called after the assigned task reports success.
class AlarmProvider extends ChangeNotifier {
  final List<Alarm> _alarms = [
    Alarm(
      id: '1',
      time: const TimeOfDay(hour: 6, minute: 30),
      repeatDays: const [true, true, true, true, true, false, false],
      label: 'Morning Run',
    ),
  ];

  Alarm? _ringingAlarm;
  Timer? _clockCheckTimer;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  Alarm? get ringingAlarm => _ringingAlarm;

  AlarmProvider() {
    // Poll every second to detect when an enabled alarm's time matches now.
    // In production this is replaced/backed by flutter_local_notifications
    // exact alarms so ringing still works while the app is backgrounded.
    _clockCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAlarms());
  }

  void _checkAlarms() {
    final now = DateTime.now();
    if (now.second != 0) return; // only fire on the minute boundary
    for (final alarm in _alarms) {
      if (!alarm.enabled) continue;
      final matchesTime = alarm.time.hour == now.hour && alarm.time.minute == now.minute;
      final matchesDay = !alarm.isRepeating || alarm.repeatDays[now.weekday - 1];
      if (matchesTime && matchesDay && _ringingAlarm == null) {
        _ringingAlarm = alarm;
        notifyListeners();
      }
    }
  }

  void addAlarm(Alarm alarm) {
    _alarms.add(alarm);
    _alarms.sort((a, b) =>
        (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));
    notifyListeners();
  }

  void updateAlarm(Alarm alarm) {
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx != -1) {
      _alarms[idx] = alarm;
      notifyListeners();
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void toggleEnabled(String id, bool enabled) {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alarms[idx] = _alarms[idx].copyWith(enabled: enabled);
      notifyListeners();
    }
  }

  /// Manually trigger ringing — useful for testing the dismissal task UI
  /// from the alarm list without waiting for the real time to hit.
  void debugTriggerRing(Alarm alarm) {
    _ringingAlarm = alarm;
    notifyListeners();
  }

  /// Called by the snooze button in AlarmRingScreen. No task required.
  void snooze() {
    final alarm = _ringingAlarm;
    if (alarm == null || alarm.snoozeMinutes <= 0) return;
    _ringingAlarm = null;
    notifyListeners();
    Timer(Duration(minutes: alarm.snoozeMinutes), () {
      _ringingAlarm = alarm;
      notifyListeners();
    });
  }

  /// Called ONLY once the required AlarmTaskType has reported success.
  /// This is the single choke point that enforces "task must be completed
  /// before the alarm can be turned off".
  void dismiss() {
    final alarm = _ringingAlarm;
    if (alarm == null) return;
    _ringingAlarm = null;
    if (alarm.deleteAfterRinging) {
      _alarms.removeWhere((a) => a.id == alarm.id);
    } else if (!alarm.isRepeating) {
      // One-shot alarms auto-disable after ringing (but aren't deleted)
      // unless deleteAfterRinging is set.
      final idx = _alarms.indexWhere((a) => a.id == alarm.id);
      if (idx != -1) _alarms[idx] = _alarms[idx].copyWith(enabled: false);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _clockCheckTimer?.cancel();
    super.dispose();
  }
}
