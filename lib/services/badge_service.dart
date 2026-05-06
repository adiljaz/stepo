/// Achievement badge definitions and persistence.
library;

import 'package:sqflite/sqflite.dart';
import '../db/step_database.dart';

class AppBadge {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final bool Function(int steps, int streak, int dailyBest, int monthTotal) condition;
  bool earned;
  DateTime? earnedAt;

  AppBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.condition,
    this.earned = false,
    this.earnedAt,
  });
}

class BadgeService {
  static const _table = 'badges';
  static Database? _db;

  static final List<AppBadge> _definitions = [
    AppBadge(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Reach 1,000 steps',
      icon: '👟',
      condition: (steps, streak, best, month) => steps >= 1000,
    ),
    AppBadge(
      id: 'daily_goal',
      title: 'Goal Getter',
      description: 'Hit your daily goal',
      icon: '🎯',
      condition: (steps, streak, best, month) => best >= 8000,
    ),
    AppBadge(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: '7-day streak',
      icon: '🔥',
      condition: (steps, streak, best, month) => streak >= 7,
    ),
    AppBadge(
      id: 'ten_k_club',
      title: '10K Club',
      description: '10,000 steps in one day',
      icon: '🏆',
      condition: (steps, streak, best, month) => best >= 10000,
    ),
    AppBadge(
      id: 'marathon_month',
      title: 'Marathon Month',
      description: '300,000 steps in a month',
      icon: '🏃',
      condition: (steps, streak, best, month) => month >= 300000,
    ),
  ];

  static Future<Database> _open() async {
    // Use StepDatabase's shared connection so both tables are always
    // guaranteed to exist before any query runs.
    return StepDatabase.openDb();
  }

  /// Returns newly earned badges given current stats.
  static Future<List<AppBadge>> check({
    required int steps,
    required int streak,
    required int dailyBest,
    required int monthTotal,
  }) async {
    final db = await _open();
    final earned = await db.query(_table);
    final earnedIds = earned.map((r) => r['id'] as String).toSet();

    final newlyEarned = <AppBadge>[];

    for (final badge in _definitions) {
      if (earnedIds.contains(badge.id)) continue;
      if (badge.condition(steps, streak, dailyBest, monthTotal)) {
        await db.insert(_table, {
          'id': badge.id,
          'earned_at': DateTime.now().toIso8601String(),
        });
        badge.earned = true;
        badge.earnedAt = DateTime.now();
        newlyEarned.add(badge);
      }
    }
    return newlyEarned;
  }

  static Future<List<AppBadge>> getAll() async {
    final db = await _open();
    final earned = await db.query(_table);
    final earnedMap = {
      for (final r in earned)
        r['id'] as String: DateTime.parse(r['earned_at'] as String)
    };
    return _definitions.map((b) {
      b.earned = earnedMap.containsKey(b.id);
      b.earnedAt = earnedMap[b.id];
      return b;
    }).toList();
  }
}
