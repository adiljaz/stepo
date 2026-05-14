// ════════════════════════════════════════════════════════════════════════════
// insight_engine.dart — Personalised Insight Engine
// ════════════════════════════════════════════════════════════════════════════
//
// Analyses the last 30 days of [DailyRecord] history from SQLite and
// generates ranked, human-readable insights for display in the HomeScreen
// InsightCarousel.
//
// Seven insight types:
//   BestDay    — "Your best day was Tuesday with 12,450 steps"
//   Streak     — "You're on a 7-day streak — your longest ever!"
//   Pattern    — "You walk 40% more on weekdays than weekends"
//   Pace       — "Your average pace improved by 8% this week"
//   Goal       — "You've hit your goal 5 out of 7 days this week"
//   Milestone  — "You've walked 100 km total since installing Stepooo"
//   TimeOfDay  — "You're most active between 7–9 AM"  (future sensor data)
//
// Results are cached in [SharedPreferences] with a date key and refreshed
// once per day to avoid redundant computation.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/step_database.dart';
import '../models/daily_record.dart';
import '../utils/logger.dart';

// ─── Insight Model ────────────────────────────────────────────────────────────

/// Identifies the category of an insight card.
enum InsightType {
  bestDay,
  streak,
  pattern,
  pace,
  goal,
  milestone,
  timeOfDay,
}

/// A single personalised insight to display in the HomeScreen carousel.
class Insight {
  final String id;
  final InsightType type;
  final String title;
  final String body;
  final String emoji;
  final double relevanceScore; // 0.0–1.0; higher = shown first
  final DateTime generatedAt;
  bool isDismissed;

  Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.emoji,
    required this.relevanceScore,
    required this.generatedAt,
    this.isDismissed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'emoji': emoji,
        'relevanceScore': relevanceScore,
        'generatedAt': generatedAt.toIso8601String(),
        'isDismissed': isDismissed,
      };

  factory Insight.fromJson(Map<String, dynamic> j) => Insight(
        id: j['id'] as String,
        type: InsightType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => InsightType.bestDay,
        ),
        title: j['title'] as String,
        body: j['body'] as String,
        emoji: j['emoji'] as String,
        relevanceScore: (j['relevanceScore'] as num).toDouble(),
        generatedAt: DateTime.parse(j['generatedAt'] as String),
        isDismissed: j['isDismissed'] as bool? ?? false,
      );
}

// ─── Engine ───────────────────────────────────────────────────────────────────

/// Computes personalised insights from [DailyRecord] history.
class InsightEngine {
  static const _kCacheKey  = 'stepooo_insights_cache';
  static const _kCacheDateKey = 'stepooo_insights_date';

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Returns ranked insights for the HomeScreen carousel.
  ///
  /// Results are cached for the day; pass [forceRefresh]=true to recompute.
  /// [dailyGoal] is the user's current step target.
  static Future<List<Insight>> generate({
    int dailyGoal = 8000,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null) return cached;
    }

    // Load last 30 days
    final records = await StepDatabase.getRecent(30);
    if (records.isEmpty) return _emptyStateInsights();

    final insights = <Insight>[];

    // Generate all insight types (non-null results only)
    final bestDay   = _bestDayInsight(records);
    final streak    = await _streakInsight(dailyGoal, records);
    final pattern   = _patternInsight(records);
    final pace      = _paceInsight(records);
    final goal      = _goalInsight(records, dailyGoal);
    final milestone = _milestoneInsight(records);
    final timeOfDay = _timeOfDayInsight(); // static heuristic for now

    if (bestDay   != null) insights.add(bestDay);
    if (streak    != null) insights.add(streak);
    if (pattern   != null) insights.add(pattern);
    if (pace      != null) insights.add(pace);
    if (goal      != null) insights.add(goal);
    if (milestone != null) insights.add(milestone);
    if (timeOfDay != null) insights.add(timeOfDay);

    // Sort by relevance, highest first
    insights.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    AppLogger.i('InsightEngine', 'Generated ${insights.length} insights');

    // Cache results
    await _saveCache(insights);
    return insights;
  }

  // ─── Insight Generators ───────────────────────────────────────────────────

  /// BestDay: "Your best day was [weekday] with [steps] steps"
  static Insight? _bestDayInsight(List<DailyRecord> records) {
    if (records.isEmpty) return null;
    final best = records.reduce(
        (a, b) => a.steps > b.steps ? a : b);
    if (best.steps < 100) return null;

    final date    = DateTime.parse(best.date);
    final weekday = _weekdayName(date.weekday);
    final stepsFmt = _fmtSteps(best.steps);

    return Insight(
      id: 'best_day_${best.date}',
      type: InsightType.bestDay,
      title: 'Personal Best! 🏆',
      body: 'Your best day was $weekday with $stepsFmt steps. Can you beat it today?',
      emoji: '🏆',
      relevanceScore: 0.75,
      generatedAt: DateTime.now(),
    );
  }

  /// Streak: "You're on a N-day streak — your longest ever!"
  static Future<Insight?> _streakInsight(
    int goal,
    List<DailyRecord> records,
  ) async {
    if (records.isEmpty) return null;

    // Current streak (consecutive days from today)
    int current = 0;
    final today = DailyRecord.today();
    for (final r in records) {
      if (r.steps >= goal) {
        current++;
      } else {
        // Allow a gap of 1 day (missed yesterday)
        if (current == 0 && r.date != today) break;
        if (current > 0) break;
      }
    }

    if (current < 2) return null;

    // Historical longest streak
    int longest = 0, running = 0;
    for (final r in records) {
      running = r.steps >= goal ? running + 1 : 0;
      if (running > longest) longest = running;
    }

    final isRecord = current >= longest;
    final body = isRecord
        ? 'You\'re on a $current-day streak — your longest ever! Keep it up! 🔥'
        : 'You\'re on a $current-day streak. Your record is $longest days — you\'re getting close!';

    return Insight(
      id: 'streak_$current',
      type: InsightType.streak,
      title: '$current-Day Streak!',
      body: body,
      emoji: '🔥',
      relevanceScore: isRecord ? 0.98 : 0.80,
      generatedAt: DateTime.now(),
    );
  }

  /// Pattern: "You walk X% more on weekdays than weekends"
  static Insight? _patternInsight(List<DailyRecord> records) {
    if (records.length < 7) return null;

    double weekdaySum = 0, weekendSum = 0;
    int weekdayCount = 0, weekendCount = 0;

    for (final r in records) {
      final dow = DateTime.parse(r.date).weekday;
      if (dow >= 1 && dow <= 5) {
        weekdaySum += r.steps;
        weekdayCount++;
      } else {
        weekendSum += r.steps;
        weekendCount++;
      }
    }

    if (weekdayCount == 0 || weekendCount == 0) return null;

    final weekdayAvg = weekdaySum / weekdayCount;
    final weekendAvg = weekendSum / weekendCount;
    if (weekdayAvg < 100 && weekendAvg < 100) return null;

    final diff = ((weekdayAvg - weekendAvg) / weekendAvg * 100).abs().round();
    if (diff < 10) return null; // Not interesting enough

    final moreDays  = weekdayAvg > weekendAvg ? 'weekdays' : 'weekends';
    final lessDays  = weekdayAvg > weekendAvg ? 'weekends' : 'weekdays';

    return Insight(
      id: 'pattern_wd',
      type: InsightType.pattern,
      title: 'Activity Pattern Found',
      body: 'You walk $diff% more on $moreDays than $lessDays. '
          '${weekdayAvg > weekendAvg ? "Try a weekend stroll to stay consistent!" : "Great weekend warrior energy!"}',
      emoji: '📊',
      relevanceScore: 0.65,
      generatedAt: DateTime.now(),
    );
  }

  /// Pace: "Your average pace improved by X% this week"
  static Insight? _paceInsight(List<DailyRecord> records) {
    if (records.length < 14) return null;

    // This week vs last week average
    final thisWeek = records.take(7).map((r) => r.steps).toList();
    final lastWeek = records.skip(7).take(7).map((r) => r.steps).toList();

    final thisAvg = thisWeek.reduce((a, b) => a + b) / thisWeek.length;
    final lastAvg = lastWeek.reduce((a, b) => a + b) / lastWeek.length;

    if (lastAvg < 100) return null;

    final pct = ((thisAvg - lastAvg) / lastAvg * 100).round();
    if (pct.abs() < 5) return null;

    final improved = pct > 0;
    return Insight(
      id: 'pace_weekly',
      type: InsightType.pace,
      title: improved ? 'You\'re Improving! 📈' : 'A Quiet Week 📉',
      body: improved
          ? 'Your daily average is up $pct% vs last week. You\'re on the right track!'
          : 'Your daily average is down ${pct.abs()}% vs last week. Tomorrow is a fresh start!',
      emoji: improved ? '📈' : '📉',
      relevanceScore: improved ? 0.85 : 0.60,
      generatedAt: DateTime.now(),
    );
  }

  /// Goal: "You've hit your goal N out of 7 days this week"
  static Insight? _goalInsight(List<DailyRecord> records, int goal) {
    if (records.length < 7) return null;
    final thisWeek = records.take(7).toList();
    final hits = thisWeek.where((r) => r.steps >= goal).length;
    if (hits == 0) return null;

    final body = hits == 7
        ? 'Perfect week! You hit your goal every single day. You\'re unstoppable! 💪'
        : 'You hit your ${_fmtSteps(goal)}-step goal $hits out of 7 days. '
          '${hits >= 5 ? "Almost perfect — keep going!" : "Every step counts!"}';

    return Insight(
      id: 'goal_week_$hits',
      type: InsightType.goal,
      title: hits == 7 ? 'Perfect Week! 🌟' : '$hits/7 Goal Days',
      body: body,
      emoji: hits == 7 ? '🌟' : '🎯',
      relevanceScore: hits == 7 ? 0.95 : 0.70,
      generatedAt: DateTime.now(),
    );
  }

  /// Milestone: total distance / steps achievements
  static Insight? _milestoneInsight(List<DailyRecord> records) {
    final totalSteps = records.fold<int>(0, (sum, r) => sum + r.steps);
    final totalKm    = records.fold<double>(0.0, (sum, r) => sum + r.distanceKm);

    // Distance milestones in km
    const milestones = [10, 25, 50, 100, 250, 500, 1000];
    for (final km in milestones.reversed) {
      if (totalKm >= km) {
        return Insight(
          id: 'milestone_${km}km',
          type: InsightType.milestone,
          title: '${km}km Milestone! 🏅',
          body: 'You\'ve walked ${totalKm.toStringAsFixed(1)} km since tracking started. '
              'That\'s like walking ${(km / 42.195).toStringAsFixed(1)} marathons!',
          emoji: '🏅',
          relevanceScore: 0.88,
          generatedAt: DateTime.now(),
        );
      }
    }

    // Step milestones
    const stepMilestones = [10000, 50000, 100000, 250000, 500000, 1000000];
    for (final steps in stepMilestones.reversed) {
      if (totalSteps >= steps) {
        return Insight(
          id: 'milestone_${steps}steps',
          type: InsightType.milestone,
          title: '${_fmtSteps(steps)} Steps Total! 🎉',
          body: 'You\'ve taken ${_fmtSteps(totalSteps)} steps in total. '
              'Amazing commitment to your health!',
          emoji: '🎉',
          relevanceScore: 0.82,
          generatedAt: DateTime.now(),
        );
      }
    }
    return null;
  }

  /// TimeOfDay: static insight (can be made dynamic with time-bucketed DB data later)
  static Insight? _timeOfDayInsight() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 10) {
      return Insight(
        id: 'time_morning',
        type: InsightType.timeOfDay,
        title: 'Morning Mover! ☀️',
        body: 'You\'re active early! Morning walks boost metabolism and mood for the whole day.',
        emoji: '☀️',
        relevanceScore: 0.55,
        generatedAt: DateTime.now(),
      );
    } else if (hour >= 18 && hour < 22) {
      return Insight(
        id: 'time_evening',
        type: InsightType.timeOfDay,
        title: 'Evening Walker 🌙',
        body: 'Evening walks are great for winding down. A consistent evening routine builds lasting habits.',
        emoji: '🌙',
        relevanceScore: 0.50,
        generatedAt: DateTime.now(),
      );
    }
    return null;
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────

  static List<Insight> _emptyStateInsights() => [
        Insight(
          id: 'welcome',
          type: InsightType.streak,
          title: 'Welcome to Stepooo! 👋',
          body: 'Start walking today and we\'ll generate personalised insights based on your activity. '
              'Your first insight appears after just a few days!',
          emoji: '👋',
          relevanceScore: 1.0,
          generatedAt: DateTime.now(),
        ),
      ];

  // ─── Cache ────────────────────────────────────────────────────────────────────

  static Future<void> _saveCache(List<Insight> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DailyRecord.today();
      final json  = insights.map((i) => i.toJson()).toList();
      await prefs.setString(_kCacheKey, jsonEncode(json));
      await prefs.setString(_kCacheDateKey, today);
    } catch (e) {
      AppLogger.w('InsightEngine', 'Cache write failed: $e');
    }
  }

  static Future<List<Insight>?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheDate = prefs.getString(_kCacheDateKey);
      if (cacheDate != DailyRecord.today()) return null; // stale

      final raw = prefs.getString(_kCacheKey);
      if (raw == null) return null;

      final list = (jsonDecode(raw) as List)
          .map((j) => Insight.fromJson(j as Map<String, dynamic>))
          .where((i) => !i.isDismissed)
          .toList();
      return list.isEmpty ? null : list;
    } catch (e) {
      AppLogger.w('InsightEngine', 'Cache read failed: $e');
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static String _fmtSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return '$steps';
  }

  static String _weekdayName(int weekday) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday',
        'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekday >= 1 && weekday <= 7 ? names[weekday] : 'that day';
  }
}
