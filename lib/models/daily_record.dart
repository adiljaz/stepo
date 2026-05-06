class DailyRecord {
  final String date; // ISO date: 'YYYY-MM-DD'
  final int steps;
  final double distanceKm;
  final double calories;
  final int floors;

  const DailyRecord({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    this.floors = 0,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'steps': steps,
        'distance': distanceKm,
        'calories': calories,
        'floors': floors,
      };

  factory DailyRecord.fromMap(Map<String, dynamic> m) => DailyRecord(
        date: m['date'] as String,
        steps: m['steps'] as int,
        distanceKm: (m['distance'] as num).toDouble(),
        calories: (m['calories'] as num).toDouble(),
        floors: (m['floors'] as num?)?.toInt() ?? 0,
      );

  static String today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
