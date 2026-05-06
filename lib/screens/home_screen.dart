import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/step_constants.dart';
import '../providers/step_provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/step_tracking_service.dart';
import '../services/badge_service.dart';
import '../services/gait_classifier.dart';
import '../widgets/activity_badge.dart';
import '../widgets/badge_unlock_dialog.dart';
import 'history_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(stepTrackingProvider.notifier).initialise();
      _checkBadges();
    });
  }

  Future<void> _checkBadges() async {
    final state = ref.read(stepStateProvider);
    final profile = ref.read(userSettingsProvider);
    final streak = 0; // simplified — db would give real streak
    final newBadges = await BadgeService.check(
      steps: state.steps,
      streak: streak,
      dailyBest: state.steps,
      monthTotal: state.steps,
    );
    if (mounted && newBadges.isNotEmpty) {
      await BadgeUnlockDialog.show(context, newBadges.first);
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stepStateProvider);
    final profile = ref.watch(userSettingsProvider);

    return Listener(
      onPointerDown: (_) =>
          ref.read(stepTrackingProvider.notifier).onUserInteraction(),
      child: Scaffold(
        backgroundColor: const Color(kBackgroundColor),
        body: _selectedNav == 0
            ? _MainView(state: state, profile: profile, ringCtrl: _ringCtrl)
            : const HistoryScreen(),
        floatingActionButton: _selectedNav == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(kPrimaryColor),
                icon: const Icon(Icons.directions_run_rounded, color: Colors.white),
                label: Text('Workout',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WorkoutScreen())),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedNav,
          onDestinationSelected: (i) => setState(() => _selectedNav = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(kPrimaryColor).withOpacity(0.1),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_rounded), label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded), label: 'History'),
          ],
        ),
      ),
    );
  }
}

class _MainView extends StatelessWidget {
  final StepTrackingState state;
  final dynamic profile;
  final AnimationController ringCtrl;
  const _MainView(
      {required this.state, required this.profile, required this.ringCtrl});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ActivityRing(state: state, profile: profile, ctrl: ringCtrl),
                const SizedBox(height: 36),
                _sectionTitle('Activity Details'),
                const SizedBox(height: 16),
                _StatsGrid(state: state),
                if (state.floors > 0) ...[
                  const SizedBox(height: 12),
                  _FloorsCard(floors: state.floors),
                ],
                const SizedBox(height: 32),
                _sectionTitle('System Status'),
                const SizedBox(height: 16),
                _IntegrityCard(state: state),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(kTextColor)));

  SliverAppBar _buildAppBar(BuildContext context) {
    final greeting = _greeting();
    final name = (profile?.name?.isNotEmpty == true) ? profile!.name : 'Athlete';
    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 65,
      pinned: true,
      backgroundColor: const Color(kBackgroundColor),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(kSecondaryTextColor),
                    fontWeight: FontWeight.w500)),
            Text(name,
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(kTextColor))),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: CircleAvatar(
            backgroundColor: const Color(kPrimaryColor).withOpacity(0.1),
            child: const Icon(Icons.person_rounded, color: Color(kPrimaryColor)),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Ring
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityRing extends StatelessWidget {
  final StepTrackingState state;
  final dynamic profile;
  final AnimationController ctrl;
  const _ActivityRing(
      {required this.state, required this.profile, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final goal = state.dailyGoal;
    final progress = state.goalProgress;

    return Center(
      child: Stack(alignment: Alignment.center, children: [
        // Ambient glow
        AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) => Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(kPrimaryColor)
                      .withOpacity(0.08 + 0.06 * ctrl.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),
        // Track ring
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 24,
            color: const Color(kPrimaryColor).withOpacity(0.08),
            strokeCap: StrokeCap.round,
          ),
        ),
        // Progress ring
        SizedBox(
          width: 250,
          height: 250,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
              value: v,
              strokeWidth: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                v >= 1.0 ? const Color(kSuccessColor) : const Color(kPrimaryColor),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
        // Center content
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('TODAY',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: const Color(kSecondaryTextColor))),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${state.steps}',
              key: ValueKey(state.steps),
              style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  color: const Color(kTextColor)),
            ),
          ),
          Text('steps',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(kSecondaryTextColor))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(kPrimaryColor).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Goal: ${_fmtK(goal)}',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(kPrimaryColor)),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmtK(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(0)}K' : '$n';
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final StepTrackingState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [
        _StatCard('Distance', state.distanceKm.toStringAsFixed(2), 'km',
            Icons.route_rounded, const Color(kAccentColor)),
        _StatCard('Calories', state.calories.toInt().toString(), 'kcal',
            Icons.local_fire_department_rounded, const Color(kSecondaryColor)),
        _StatCard('Hardware', state.hardwareSteps.toString(), 'steps',
            Icons.memory_rounded, const Color(kPrimaryColor)),
        _StatCard(
            'Integrity',
            '${(100 - (state.lastFraudScore * 100)).toInt()}%',
            'score',
            Icons.verified_user_rounded,
            const Color(kSuccessColor)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.unit, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(kSecondaryTextColor))),
            ]),
            Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(kTextColor))),
                  const SizedBox(width: 3),
                  Text(unit,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(kSecondaryTextColor))),
                ]),
          ]),
    );
  }
}

class _FloorsCard extends StatelessWidget {
  final int floors;
  const _FloorsCard({required this.floors});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(kAccentColor).withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.stairs_rounded,
              size: 20, color: Color(kAccentColor)),
        ),
        const SizedBox(width: 14),
        Text('Floors Climbed',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, color: const Color(kTextColor))),
        const Spacer(),
        Text('$floors',
            style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(kAccentColor))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System Integrity Card
// ─────────────────────────────────────────────────────────────────────────────

class _IntegrityCard extends StatelessWidget {
  final StepTrackingState state;
  const _IntegrityCard({required this.state});

  @override
  Widget build(BuildContext context) {
    Color statusColor = const Color(kSuccessColor);
    if (state.lastFraudScore > 0.3) statusColor = const Color(kWarningColor);
    if (state.lastFraudScore > 0.7) statusColor = const Color(kErrorColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: state.lastFraudScore > 0.5
                ? const Color(kErrorColor).withOpacity(0.2)
                : Colors.transparent),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              state.lastFraudScore > 0.5
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Motion Analysis',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: const Color(kTextColor))),
                Text(
                  state.lastRejectionReason ?? 'All systems normal',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(kSecondaryTextColor)),
                ),
              ])),
          ActivityBadge(status: state.gaitLabel.name.toUpperCase()),
        ]),
        if (state.calibrationProgress < kCalibrationDoneSteps) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.calibrationProgress / kCalibrationDoneSteps,
                backgroundColor: const Color(kBackgroundColor),
                valueColor: const AlwaysStoppedAnimation(Color(kPrimaryColor)),
                minHeight: 8,
              ),
            )),
            const SizedBox(width: 10),
            Text(
              '${((state.calibrationProgress / kCalibrationDoneSteps) * 100).toInt()}%',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(kPrimaryColor)),
            ),
          ]),
        ],
      ]),
    );
  }
}
