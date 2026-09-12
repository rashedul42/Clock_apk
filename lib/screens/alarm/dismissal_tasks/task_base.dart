import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Every dismissal task widget calls [onCompleted] exactly once, when (and
/// only when) the user has genuinely satisfied the challenge. AlarmRingScreen
/// wires this to AlarmProvider.dismiss() — nothing else in the task widgets
/// is allowed to silence the alarm. This is the enforcement boundary of the
/// whole Task-Based Alarm Dismissal System.
typedef TaskCompletedCallback = void Function();

/// Common chrome (title, progress hint, instructions) wrapped around each
/// task's unique interactive content, so all 5 tasks look consistent.
class TaskScaffold extends StatelessWidget {
  final String emoji;
  final String title;
  final String instructions;
  final Widget child;
  final Widget? footer;

  const TaskScaffold({
    super.key,
    required this.emoji,
    required this.title,
    required this.instructions,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(emoji, style: const TextStyle(fontSize: 40), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          instructions,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Expanded(child: child),
        if (footer != null) footer!,
      ],
    );
  }
}

/// Standard "N of M complete" pill shown at the top of a task, e.g. for
/// math problems answered, or reps counted.
class TaskProgressPill extends StatelessWidget {
  final int current;
  final int total;

  const TaskProgressPill({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
