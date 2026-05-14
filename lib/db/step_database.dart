import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/daily_record.dart';

/// Stepooo v7.0 Database Layer.
/// 
/// Implements the 4-tier event logging and audit tables for the AI engine.
class StepDatabase {
  static String dbName    = 'stepooo.db';
  static const _version   = 5; 
  
  static const _tableDaily      = 'daily_steps';
  static const _tableBadges     = 'badges';
  static const _tableProfiles   = 'device_profiles';
  static const _tableCheckpoints = 'step_checkpoints';

  // v7.0 AI Architecture Tables
  static const _tableStepEvents   = 'step_events';
  static const _tableRejected     = 'rejected_steps';
  static const _tablePending      = 'pending_steps';
  static const _tableGaitSessions = 'gait_sessions';

  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      path.join(dbPath, dbName),
      version: _version,
      onCreate: (db, v) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 5) {
          await _createTables(db);
        }
      },
    );
    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    // Legacy support tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableDaily (
        date     TEXT PRIMARY KEY,
        steps    INTEGER NOT NULL DEFAULT 0,
        distance REAL    NOT NULL DEFAULT 0,
        calories REAL    NOT NULL DEFAULT 0,
        floors   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableBadges (
        id        TEXT PRIMARY KEY,
        earned_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableProfiles (
        device_model    TEXT PRIMARY KEY,
        thresholds_json TEXT NOT NULL,
        updated_at      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCheckpoints (
        id       TEXT PRIMARY KEY,
        steps    INTEGER NOT NULL,
        at       TEXT    NOT NULL,
        date     TEXT    NOT NULL
      )
    ''');

    // v7.0 Stage 7 & 8 Audit Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableStepEvents (
        id                 TEXT PRIMARY KEY,
        timestamp          TEXT NOT NULL,
        tier_used          INTEGER,
        ml_class           INTEGER,
        ml_confidence      REAL,
        fft_dominant_freq  REAL,
        hardware_delta     INTEGER,
        isi_ms             REAL,
        confirmed          INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableRejected (
        id             TEXT PRIMARY KEY,
        timestamp      TEXT NOT NULL,
        reject_reason  TEXT,
        ml_confidence  REAL,
        fft_freq       REAL,
        raw_tensor     BLOB
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tablePending (
        id          TEXT PRIMARY KEY,
        timestamp   TEXT NOT NULL,
        tier        INTEGER,
        status      TEXT,
        expires_at  TEXT,
        raw_tensor  BLOB
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableGaitSessions (
        id              TEXT PRIMARY KEY,
        date            TEXT NOT NULL,
        total_steps     INTEGER,
        avg_confidence  REAL,
        tier1_pct       REAL,
        tier2_pct       REAL,
        tier3_pct       REAL,
        reject_pct      REAL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_ts ON $_tableStepEvents(timestamp)');
  }

  // ─── STAGE 6 & 7 Database API ──────────────────────────────────────────────

  static Future<void> logStepEvent({
    required String id,
    required DateTime ts,
    required int tier,
    required int mlClass,
    required double mlConf,
    required double fftFreq,
    required int hwDelta,
    required double isi,
    bool confirmed = true,
  }) async {
    final db = await getDatabase();
    await db.insert(_tableStepEvents, {
      'id': id,
      'timestamp': ts.toIso8601String(),
      'tier_used': tier,
      'ml_class': mlClass,
      'ml_confidence': mlConf,
      'fft_dominant_freq': fftFreq,
      'hardware_delta': hwDelta,
      'isi_ms': isi,
      'confirmed': confirmed ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> logRejectedStep({
    required String id,
    required DateTime ts,
    required String reason,
    required double conf,
    required double fft,
    Uint8List? tensor,
  }) async {
    final db = await getDatabase();
    await db.insert(_tableRejected, {
      'id': id,
      'timestamp': ts.toIso8601String(),
      'reject_reason': reason,
      'ml_confidence': conf,
      'fft_freq': fft,
      'raw_tensor': tensor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> savePendingStep({
    required String id,
    required DateTime ts,
    required int tier,
    required DateTime expiresAt,
    Uint8List? tensor,
  }) async {
    final db = await getDatabase();
    await db.insert(_tablePending, {
      'id': id,
      'timestamp': ts.toIso8601String(),
      'tier': tier,
      'status': 'pending',
      'expires_at': expiresAt.toIso8601String(),
      'raw_tensor': tensor,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Legacy Support / Daily Records ────────────────────────────────────────

  static Future<void> upsertToday({
    required int steps,
    required double distanceKm,
    required double calories,
    int floors = 0,
  }) async {
    final db = await getDatabase();
    await db.insert(
      _tableDaily,
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

  static Future<List<DailyRecord>> getRecent(int days) async {
    final db = await getDatabase();
    final rows = await db.query(_tableDaily, orderBy: 'date DESC', limit: days);
    return rows.map(DailyRecord.fromMap).toList();
  }

  static Future<int> getStepsForDate(String date) async {
    final db = await getDatabase();
    final rows = await db.query(_tableDaily, where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return 0;
    return rows.first['steps'] as int;
  }

  static Future<DailyRecord?> getPersonalBest() async {
    final db = await getDatabase();
    final rows = await db.query(_tableDaily, orderBy: 'steps DESC', limit: 1);
    if (rows.isEmpty) return null;
    return DailyRecord.fromMap(rows.first);
  }

  static Future<List<DailyRecord>> getLast7Days() => getRecent(7);

  static Future<Map<String, dynamic>?> getLastCheckpoint([String? date]) async {
    final db = await getDatabase();
    final where = date != null ? 'date = ?' : null;
    final args = date != null ? [date] : null;
    final rows = await db.query(_tableCheckpoints, where: where, whereArgs: args, orderBy: 'at DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> writeCheckpoint({
    required String id,
    required int steps,
    required DateTime at,
    required String date,
  }) async {
    final db = await getDatabase();
    await db.insert(_tableCheckpoints, {
      'id': id,
      'steps': steps,
      'at': at.toIso8601String(),
      'date': date,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
