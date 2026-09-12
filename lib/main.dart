import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/alarm_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/stopwatch_provider.dart';
import 'providers/world_clock_provider.dart';
import 'screens/home/main_nav_screen.dart';
import 'screens/alarm/alarm_ring_screen.dart';

void main() {
  runApp(const ClockApp());
}

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider(create: (_) => WorldClockProvider()),
      ],
      child: MaterialApp(
        title: 'Clock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Watches AlarmProvider.ringingAlarm and swaps the entire app content for
/// the full-screen AlarmRingScreen ("Alarm Challenge Screen") whenever an
/// alarm fires — this is what makes the dismissal task unavoidable: the
/// normal app UI (including the alarm list, its toggles, and the OS back
/// gesture handling inside MainNavScreen) is simply not in the widget tree
/// while a task must be completed.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final ringing = context.select<AlarmProvider, bool>((p) => p.ringingAlarm != null);
    return ringing ? const AlarmRingScreen() : const MainNavScreen();
  }
}
