import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../alarm/alarm_list_screen.dart';
import '../world_clock/world_clock_screen.dart';
import '../timer/timer_screen.dart';
import '../stopwatch/stopwatch_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  final _screens = const [
    AlarmListScreen(),
    WorldClockScreen(),
    TimerScreen(),
    StopwatchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm_rounded), label: 'Alarm'),
          BottomNavigationBarItem(icon: Icon(Icons.public_rounded), label: 'World Clock'),
          BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom_rounded), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Stopwatch'),
        ],
      ),
    );
  }
}
