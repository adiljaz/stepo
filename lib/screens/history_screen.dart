import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
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
      backgroundColor: const Color(kBackgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(kBackgroundColor),
        elevation: 0,
        title: Text('History',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: const Color(kTextColor))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(kTextColor)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<_HistoryData>(
        future: _loadData(profile.dailyGoalSteps),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'History unavailable\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(kSecondaryTextColor)),
                ),
              ),
            );
          }
          if (snap.connectionState != ConnectionState.done || snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return _HistoryBody(data: data, goal: profile.dailyGoalSteps);
        },
      ),
    );
  }

  Future<_HistoryData> _loadData(int goal) async {
    final records = await StepDatabase.getLast7Days();
    final streak = await StepDatabase.getStreak(goal);
    final pb = await StepDatabase.getPersonalBest();
    return _HistoryData(records: records, streak: streak, personalBest: pb);
  }
}

class _HistoryData {
  final List<DailyRecord> records;
  final int streak;
  final DailyRecord? personalBest;
  const _HistoryData(
      {required this.records, required this.streak, this.personalBest});
}

class _HistoryBody extends StatelessWidget {
  final _HistoryData data;
  final int goal;
  const _HistoryBody({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    // Compute weekly averages
    final thisWeek = data.records;
    final thisAvg = thisWeek.isEmpty
        ? 0
        : thisWeek.map((r) => r.steps).reduce((a, b) => a + b) ~/
            thisWeek.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 8),
        // ── Summary chips ────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _SummaryCard(
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(kSecondaryColor),
                  label: 'Streak',
                  value: '${data.streak}d')),
          const SizedBox(width: 12),
          Expanded(
              child: _SummaryCard(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(kWarningColor),
                  label: 'Best Day',
                  value: data.personalBest == null
                      ? '–'
                      : '${(data.personalBest!.steps / 1000).toStringAsFixed(1)}K')),
          const SizedBox(width: 12),
          Expanded(
              child: _SummaryCard(
                  icon: Icons.bar_chart_rounded,
                  color: const Color(kPrimaryColor),
                  label: 'Avg/Day',
                  value: '${(thisAvg / 1000).toStringAsFixed(1)}K')),
        ]),
        const SizedBox(height: 28),
        // ── 7-day bar chart ──────────────────────────────────────────────
        Text('Last 7 Days',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(kTextColor))),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: _StepBarChart(records: data.records, goal: goal),
        ),
        const SizedBox(height: 28),
        // ── Daily list ───────────────────────────────────────────────────
        Text('Daily Breakdown',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(kTextColor))),
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
  const _SummaryCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(kTextColor))),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11, color: const Color(kSecondaryTextColor))),
      ]),
    );
  }
}

class _StepBarChart extends StatelessWidget {
  final List<DailyRecord> records;
  final int goal;
  const _StepBarChart({required this.records, required this.goal});

  @override
  Widget build(BuildContext context) {
    final reversed = records.reversed.toList(); // oldest first
    final maxY = ([goal.toDouble(), ...records.map((r) => r.steps.toDouble())]
            .reduce((a, b) => a > b ? a : b) *
        1.2);

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= reversed.length) return const SizedBox();
                final parts = reversed[idx].date.split('-');
                return Text('${parts[2]}/${parts[1]}',
                    style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: const Color(kSecondaryTextColor)));
              },
              reservedSize: 28,
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.black.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(reversed.length, (i) {
          final r = reversed[i];
          final hitGoal = r.steps >= goal;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: r.steps.toDouble(),
              color: hitGoal ? const Color(kSuccessColor) : const Color(kPrimaryColor),
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ]);
        }),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: goal.toDouble(),
            color: const Color(kWarningColor).withOpacity(0.5),
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => 'Goal',
              style: GoogleFonts.outfit(fontSize: 10, color: const Color(kWarningColor)),
            ),
          ),
        ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(
          hitGoal ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: hitGoal ? const Color(kSuccessColor) : Colors.black26,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.date,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: const Color(kTextColor))),
            Text(
                '${record.distanceKm.toStringAsFixed(2)} km  ·  ${record.calories.toInt()} kcal',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: const Color(kSecondaryTextColor))),
          ]),
        ),
        Text('${record.steps}',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: hitGoal ? const Color(kSuccessColor) : const Color(kTextColor))),
      ]),
    );
  }
}
