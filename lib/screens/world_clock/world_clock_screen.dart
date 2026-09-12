import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/world_clock_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/painters/big_ben_painter.dart';

class WorldClockScreen extends StatelessWidget {
  const WorldClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = context.watch<WorldClockProvider>();
    final time = wc.selectedCityTime;

    return SafeArea(
      child: Column(
        children: [
          // ---- Top app bar ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                Text(wc.selectedCity.city, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.add_rounded), onPressed: () {}),
                IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () {}),
              ],
            ),
          ),
          // ---- Top half: Big Ben illustration ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFEFF3F8),
              alignment: Alignment.center,
              child: BigBenTower(time: time, width: 200, height: 220),
            ),
          ),
          // ---- Bottom half: digital display ----
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('hh:mm:ss a').format(time),
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(time),
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wc.selectedCity.label,
                    style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < wc.cities.length; i++)
                        ChoiceChip(
                          label: Text(wc.cities[i].city),
                          selected: wc.selectedIndex == i,
                          onSelected: (_) => context.read<WorldClockProvider>().selectCity(i),
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
}
