import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';
import '../../theme/app_theme.dart';
import 'add_alarm_screen.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarms = context.watch<AlarmProvider>().alarms;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alarm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddAlarmScreen()),
            ),
          ),
        ],
      ),
      body: alarms.isEmpty
          ? const Center(child: Text('No alarms yet', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alarms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AlarmTile(alarm: alarms[i]),
            ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final Alarm alarm;
  const _AlarmTile({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddAlarmScreen(existing: alarm)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.time.format(context),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: alarm.enabled ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          alarm.label.isEmpty ? alarm.repeatSummary : '${alarm.label} · ${alarm.repeatSummary}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        if (alarm.taskConfig.hasTask) ...[
                          const SizedBox(width: 6),
                          Text(alarm.taskConfig.taskType!.icon, style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Debug affordance: fires the alarm immediately so the
              // Task-Based Alarm Dismissal System (AlarmRingScreen) can be
              // exercised without waiting for the real clock. Remove or
              // hide behind a debug flag for production builds.
              IconButton(
                tooltip: 'Test ring now',
                icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.textSecondary),
                onPressed: () => context.read<AlarmProvider>().debugTriggerRing(alarm),
              ),
              Switch(
                value: alarm.enabled,
                onChanged: (v) => context.read<AlarmProvider>().toggleEnabled(alarm.id, v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
