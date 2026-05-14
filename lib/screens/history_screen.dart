import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';
import '../db/step_database.dart';
import '../models/daily_record.dart';
import '../providers/user_settings_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userSettingsProvider);
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.kBackgroundColor,
        elevation: 0,
        title: Text(
          'History',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: AppConfig.kTextColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppConfig.kTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<_HistoryData>(
        future: _loadData(profile.dailyGoalSteps),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'History unavailable\n${snap.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor),
              ),
            );
          }
          if (snap.connectionState != ConnectionState.done ||
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return _HistoryBody(data: data, goal: profile.dailyGoalSteps);
        },
      ),
    );
  }

  Future<_HistoryData> _loadData(int goal) async {
    final records = await StepDatabase.getRecent(30); // Get last 30 days
    return _HistoryData(records: records, streak: 0, personalBest: null);
  }
}

class _HistoryData {
  final List<DailyRecord> records;
  final int streak;
  final DailyRecord? personalBest;
  const _HistoryData({
    required this.records,
    required this.streak,
    this.personalBest,
  });
}

class _HistoryBody extends StatelessWidget {
  final _HistoryData data;
  final int goal;
  const _HistoryBody({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    if (data.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppConfig.kPrimaryColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity recorded yet',
              style: GoogleFonts.outfit(
                color: AppConfig.kSecondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final thisAvg =
        data.records.map((r) => r.steps).reduce((a, b) => a + b) ~/
        data.records.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.local_fire_department_rounded,
                color: AppConfig.kSecondaryColor,
                label: 'Streak',
                value: '${data.streak}d',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.bar_chart_rounded,
                color: AppConfig.kPrimaryColor,
                label: 'Avg/Day',
                value: '${(thisAvg / 1000).toStringAsFixed(1)}K',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Daily Breakdown',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConfig.kTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ...data.records.map((r) => _DayRow(record: r, goal: goal)),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConfig.kTextColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppConfig.kSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyRecord record;
  final int goal;
  const _DayRow({required this.record, required this.goal});

  @override
  Widget build(BuildContext context) {
    final hitGoal = record.steps >= goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (hitGoal ? AppConfig.kSuccessColor : Colors.grey)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hitGoal ? Icons.check_rounded : Icons.calendar_today_rounded,
              color: hitGoal ? AppConfig.kSuccessColor : Colors.grey,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.date,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppConfig.kTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.distanceKm.toStringAsFixed(2)} km  ·  ${record.calories.toInt()} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppConfig.kSecondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${record.steps}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: hitGoal ? AppConfig.kSuccessColor : AppConfig.kTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
