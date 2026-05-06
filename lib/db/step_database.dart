import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/daily_record.dart';

class StepDatabase {
  static const _dbName = 'stepooo.db';
  static const _version = 2;  // bumped: consolidated badges table into same DB
  static const _table = 'daily_steps';
  static const _badgeTable = 'badges';

  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      path.join(dbPath, _dbName),
      version: _version,
      onCreate: (db, v) async {
        // Create both tables in a single transaction so either both exist or neither
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_table (
            date     TEXT PRIMARY KEY,
            steps    INTEGER NOT NULL DEFAULT 0,
            distance REAL    NOT NULL DEFAULT 0,
            calories REAL    NOT NULL DEFAULT 0,
            floors   INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_badgeTable (
            id        TEXT PRIMARY KEY,
            earned_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        // v1 had only one table depending on which service opened first
        // v2 ensures both tables exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_table (
            date     TEXT PRIMARY KEY,
            steps    INTEGER NOT NULL DEFAULT 0,
            distance REAL    NOT NULL DEFAULT 0,
            calories REAL    NOT NULL DEFAULT 0,
            floors   INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_badgeTable (
            id        TEXT PRIMARY KEY,
            earned_at TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  /// Public accessor so other services (e.g. BadgeService) can share
  /// the same Database connection and avoid the table-creation race condition.
  static Future<Database> openDb() => _open();

  /// Upserts today's record.
  static Future<void> upsertToday({
    required int steps,
    required double distanceKm,
    required double calories,
    int floors = 0,
  }) async {
    final db = await _open();
    await db.insert(
      _table,
      DailyRecord(
        date: DailyRecord.today(),
        steps: steps,
        distanceKm: distanceKm,
        calories: calories,
        floors: floors,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the last [days] daily records, most recent first.
  static Future<List<DailyRecord>> getRecent(int days) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      orderBy: 'date DESC',
      limit: days,
    );
    return rows.map(DailyRecord.fromMap).toList();
  }

  /// Returns the 7 most recent records for the history chart.
  static Future<List<DailyRecord>> getLast7Days() => getRecent(7);

  /// Returns the current streak in days (consecutive days meeting goal).
  static Future<int> getStreak(int goalSteps) async {
    final records = await getRecent(365);
    int streak = 0;
    for (final r in records) {
      if (r.steps >= goalSteps) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Returns the personal best day.
  static Future<DailyRecord?> getPersonalBest() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'steps DESC', limit: 1);
    return rows.isEmpty ? null : DailyRecord.fromMap(rows.first);
  }

  /// Returns steps for a specific date string (YYYY-MM-DD).
  static Future<int> getStepsForDate(String date) async {
    final db = await _open();
    final rows = await db.query(_table, where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return 0;
    return (rows.first['steps'] as int?) ?? 0;
  }
}
