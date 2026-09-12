import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stopwatch_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/painters/seven_segment_painter.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = context.watch<StopwatchProvider>();

    return SafeArea(
      child: Column(
        children: [
          // ---- Top half: retro LCD panel ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF10231A),
              alignment: Alignment.center,
              child: LcdPanel(text: sw.formatted, digitHeight: 56),
            ),
          ),
          // ---- Bottom half: minimalist controls ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: sw.laps.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final lapIndex = sw.laps.length - i;
                        return ListTile(
                          dense: true,
                          leading: Text('Lap $lapIndex', style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: Text(
                            _formatDuration(sw.laps[i]),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CircleButton(
                        label: sw.isRunning ? 'Lap' : 'Reset',
                        color: AppColors.cardGrey,
                        textColor: AppColors.textPrimary,
                        onTap: sw.isRunning ? sw.lap : sw.reset,
                      ),
                      _CircleButton(
                        label: sw.isRunning ? 'Pause' : 'Start',
                        color: sw.isRunning ? AppColors.danger : AppColors.accent,
                        textColor: Colors.white,
                        large: true,
                        icon: sw.isRunning ? Icons.pause : Icons.play_arrow,
                        onTap: sw.isRunning ? sw.pause : sw.start,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$cs';
  }
}

class _CircleButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool large;
  final IconData? icon;

  const _CircleButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.large = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 88.0 : 64.0;
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon ?? Icons.circle, color: textColor, size: large ? 34 : 22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
