import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';
import '../db/step_database.dart';
import '../models/daily_record.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserSettingsCubit, UserProfile>(
      builder: (context, profile) {
        return Scaffold(
          backgroundColor: AppConfig.kBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                  title: Text(
                    'HISTORY',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.kTextColor,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<_HistoryData>(
                    future: _loadData(profile.dailyGoalSteps),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done || snap.data == null) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: CircularProgressIndicator(color: AppConfig.kPrimaryColor),
                        ));
                      }
                      final data = snap.data!;
                      return _HistoryBody(data: data, goal: profile.dailyGoalSteps);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_HistoryData> _loadData(int goal) async {
    final records = await StepDatabase.getRecent(30);
    return _HistoryData(records: records, streak: 0);
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
        Row(
          children: [
            Expanded(child: _SummaryNode(label: 'CURRENT STREAK', value: '${data.streak}D', color: AppConfig.kSecondaryColor)),
            const SizedBox(width: 16),
            Expanded(child: _SummaryNode(label: 'DAILY AVERAGE', value: '${(thisAvg / 1000).toStringAsFixed(1)}K', color: AppConfig.kPrimaryColor)),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Text(
              'RECENT TIMELINE',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppConfig.kSecondaryTextColor,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Icon(Icons.tune_rounded, color: AppConfig.kSecondaryTextColor, size: 18),
          ],
        ),
        const SizedBox(height: 24),
        ...data.records.map((r) => _HistoryEntry(record: r, goal: goal)),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _SummaryNode extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryNode({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: BorderRadius.circular(AppConfig.kCardRadius),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final DailyRecord record;
  final int goal;
  const _HistoryEntry({required this.record, required this.goal});

  @override
  Widget build(BuildContext context) {
    final hitGoal = record.steps >= goal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppConfig.kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: (hitGoal ? AppConfig.kPrimaryColor : AppConfig.kSecondaryTextColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hitGoal ? Icons.verified_rounded : Icons.calendar_month_rounded,
                color: hitGoal ? AppConfig.kPrimaryColor : AppConfig.kSecondaryTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.date, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.kTextColor)),
                  Text(
                    '${record.distanceKm.toStringAsFixed(1)}km • ${record.calories.toInt()}kcal',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              record.steps.toString(),
              style: GoogleFonts.outfit(
                fontSize: 22, 
                fontWeight: FontWeight.w800,
                color: hitGoal ? AppConfig.kPrimaryColor : AppConfig.kTextColor,
              ),
            ),
          ],
        ),
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
          Icon(Icons.query_stats_rounded, size: 64, color: AppConfig.kPrimaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('NO DATA DETECTED', style: GoogleFonts.spaceGrotesk(color: AppConfig.kSecondaryTextColor, letterSpacing: 2)),
        ],
      ),
    );
  }
}

