import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/world_city.dart';

class WorldClockProvider extends ChangeNotifier {
  final List<WorldCity> _cities = List.of(WorldCity.defaults);
  int _selectedIndex = 0;
  Timer? _ticker;
  DateTime _now = DateTime.now().toUtc();

  WorldClockProvider() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now().toUtc();
      notifyListeners();
    });
  }

  List<WorldCity> get cities => List.unmodifiable(_cities);
  WorldCity get selectedCity => _cities[_selectedIndex];
  int get selectedIndex => _selectedIndex;

  /// Current local time in the selected city, using its fixed UTC offset.
  /// (For DST-correct results, swap this for the `timezone` package's
  /// TZDateTime.from(_now, getLocation(selectedCity.timezoneName)).)
  DateTime get selectedCityTime => _now.add(selectedCity.utcOffset);

  void selectCity(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void addCity(WorldCity city) {
    _cities.add(city);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
