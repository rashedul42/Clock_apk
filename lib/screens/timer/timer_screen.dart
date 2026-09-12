import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/timer_preset.dart';
import '../../providers/timer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/painters/hourglass_painter.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    return SafeArea(
      child: Column(
        children: [
          // ---- Top half: animated hourglass ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: AppColors.accentSoft,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HourglassWidget(fraction: timer.remainingFraction, isRunning: timer.isRunning, size: 180),
                  const SizedBox(height: 12),
                  Text(
                    timer.formatted,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          // ---- Bottom half: presets + play control ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: [
                        for (final preset in TimerPreset.defaults)
                          _PresetCard(
                            preset: preset,
                            onTap: () => context.read<TimerProvider>().setDuration(preset.duration),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.large(
                    backgroundColor: AppColors.accent,
                    onPressed: () {
                      final p = context.read<TimerProvider>();
                      timer.isRunning ? p.pause() : p.start();
                    },
                    child: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow, size: 34),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final TimerPreset preset;
  final VoidCallback onTap;
  const _PresetCard({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(preset.icon, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(preset.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      _durationLabel(preset.duration),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}
