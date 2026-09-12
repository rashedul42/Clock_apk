class WorldCity {
  final String city;
  final String timezoneName; // IANA name, e.g. "Asia/Dhaka"
  final String label; // e.g. "Bangladesh Standard Time"
  final Duration utcOffset; // fallback fixed offset if timezone db unavailable

  const WorldCity({
    required this.city,
    required this.timezoneName,
    required this.label,
    required this.utcOffset,
  });

  static const List<WorldCity> defaults = [
    WorldCity(
      city: 'Dhaka',
      timezoneName: 'Asia/Dhaka',
      label: 'Bangladesh Standard Time',
      utcOffset: Duration(hours: 6),
    ),
    WorldCity(
      city: 'London',
      timezoneName: 'Europe/London',
      label: 'Greenwich Mean Time',
      utcOffset: Duration(hours: 0),
    ),
    WorldCity(
      city: 'New York',
      timezoneName: 'America/New_York',
      label: 'Eastern Standard Time',
      utcOffset: Duration(hours: -5),
    ),
    WorldCity(
      city: 'Tokyo',
      timezoneName: 'Asia/Tokyo',
      label: 'Japan Standard Time',
      utcOffset: Duration(hours: 9),
    ),
  ];
}
