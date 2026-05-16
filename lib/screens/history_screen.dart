import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/step_database.dart';
import '../models/daily_record.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_settings_cubit.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserSettingsCubit, UserProfile>(
      builder: (context, profile) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Weekly Steps",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FutureBuilder<_HistoryData>(
              future: _loadData(profile.dailyGoalSteps, profile.streakCount),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done || snap.data == null) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ));
                }
                final data = snap.data!;
                return _HistoryBody(data: data, goal: profile.dailyGoalSteps);
              },
            ),
          ),
        );
      },
    );
  }

  Future<_HistoryData> _loadData(int goal, int streak) async {
    final records = await StepDatabase.getRecent(30);
    return _HistoryData(records: records, streak: streak);
  }
}

class _HistoryData {
  final List<DailyRecord> records;
  final int streak;
  const _HistoryData({required this.records, required this.streak});
}

class _HistoryBody extends StatelessWidget {
  final _HistoryData data;
  final int goal;
  const _HistoryBody({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    if (data.records.isEmpty) return const _EmptyState();

    final thisAvg = data.records.map((r) => r.steps).reduce((a, b) => a + b) ~/ data.records.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          _getDateRangeLabel(data.records),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'CURRENT STREAK', value: '${data.streak}D', color: Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryCard(label: 'DAILY AVERAGE', value: '${(thisAvg / 1000).toStringAsFixed(1)}K', color: AppTheme.primaryGreen)),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'RECENT ACTIVITY',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.textLight,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...data.records.map((r) => _HistoryCard(record: r, goal: goal)),
        const SizedBox(height: 120),
      ],
    );
  }

  String _getDateRangeLabel(List<DailyRecord> records) {
    if (records.isEmpty) return "No Records";
    final latest = DateTime.parse(records.first.date);
    final earliest = DateTime.parse(records.last.date);
    final months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${earliest.day} ${months[earliest.month]} - ${latest.day} ${months[latest.month]}";
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textLight, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DailyRecord record;
  final int goal;
  const _HistoryCard({required this.record, required this.goal});

  @override
  Widget build(BuildContext context) {
    final hitGoal = record.steps >= goal;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (hitGoal ? AppTheme.primaryGreen : AppTheme.textLight).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hitGoal ? Icons.verified_user_rounded : Icons.calendar_today_rounded,
              color: hitGoal ? AppTheme.primaryGreen : AppTheme.textLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(
                  '${record.distanceKm.toStringAsFixed(1)}km • ${record.calories.toInt()}kcal',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.steps.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900,
                  color: hitGoal ? AppTheme.primaryGreen : AppTheme.textDark,
                ),
              ),
              Text(
                "Steps",
                style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.textLight.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No activity recorded yet', style: GoogleFonts.outfit(color: AppTheme.textLight, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

