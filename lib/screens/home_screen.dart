import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stepooo/theme/app_theme.dart';
import '../cubits/step_tracker_cubit.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';

import 'social_screen.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

import 'ranking_screen.dart';
import 'challenges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<StepTrackerCubit, StepTrackerState>(
      builder: (context, state) {
        return BlocBuilder<UserSettingsCubit, UserProfile>(
          builder: (context, profile) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAF8),
              body: IndexedStack(
                index: _selectedNav,
                children: [
                  _DashboardView(state: state, profile: profile),
                  const SocialScreen(),
                  const RankingScreen(),
                  const ChallengesScreen(),
                  const SettingsScreen(),
                ],
              ),
              floatingActionButton: _selectedNav == 0 ? FloatingActionButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                backgroundColor: AppTheme.primaryGreen,
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ) : null,
              bottomNavigationBar: _StepUpNavBar(
                selectedIndex: _selectedNav,
                onTap: (index) {
                  setState(() => _selectedNav = index);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardView extends StatelessWidget {
  final StepTrackerState state;
  final UserProfile profile;
  const _DashboardView({required this.state, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.name.isNotEmpty ? profile.name : "Arjun";

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?u=arjun'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning,",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "$name 👋",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Progress Circle
            Center(child: _StepProgressRing(steps: state.steps, goal: 10000)),

            const SizedBox(height: 30),

            // Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(
                  icon: Icons.location_on_rounded,
                  value: state.distanceKm.toStringAsFixed(2),
                  label: "km",
                  color: Colors.blue,
                ),
                _MetricItem(
                  icon: Icons.local_fire_department_rounded,
                  value: state.calories.toInt().toString(),
                  label: "kcal",
                  color: Colors.orange,
                ),
                _MetricItem(
                  icon: Icons.access_time_filled_rounded,
                  value: (state.steps / 100).toInt().toString(),
                  label: "min",
                  color: Colors.cyan,
                ),
                _MetricItem(
                  icon: Icons.stairs_rounded,
                  value: state.flightsOfStairs.toString(),
                  label: "floors",
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Streak Card
            const _StreakCard(),

            const SizedBox(height: 20),

            // Weekly Steps Card
            const _WeeklyStepsCard(),

            const SizedBox(height: 20),

            // Insight Card
            const _InsightCard(),

            const SizedBox(height: 20),

            // Quick Actions
            Text(
              "Quick Actions",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _QuickActionBtn(
                    icon: Icons.auto_awesome_rounded,
                    label: "Challenges",
                    color: Color(0xFFE8F5E9),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickActionBtn(
                    icon: Icons.people_rounded,
                    label: "Friends",
                    color: Color(0xFFE3F2FD),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickActionBtn(
                    icon: Icons.leaderboard_rounded,
                    label: "Leaderboard",
                    color: Color(0xFFFFF3E0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }
}

class _StepProgressRing extends StatelessWidget {
  final int steps;
  final int goal;
  const _StepProgressRing({required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFF0F0F0),
              color: AppTheme.primaryGreen,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Today's Steps",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                steps.toLocaleString(),
                style: GoogleFonts.outfit(
                  fontSize: 42,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                "/ $goal",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(progress * 100).toInt()}% Completed",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Streak",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "5",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "Days",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Complete 8,000+ steps daily to keep\nyour streak alive.",
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                ["M", "T", "W", "T", "F", "S", "S"].map((day) {
                  final isToday = day == "F";
                  final isDone = ["M", "T", "W", "T", "F"].contains(day);
                  return Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              isDone
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child:
                            isDone
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                                : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color:
                              isToday ? AppTheme.textDark : AppTheme.textLight,
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStepsCard extends StatelessWidget {
  const _WeeklyStepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly Steps",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "54,721",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    "Total Steps",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: AppTheme.primaryGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "+ 12%",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  [40, 60, 45, 80, 55, 30, 20].map((h) {
                    return Container(
                      width: 12,
                      height: h.toDouble(),
                      decoration: BoxDecoration(
                        color:
                            h > 50
                                ? AppTheme.primaryGreen
                                : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                ["M", "T", "W", "T", "F", "S", "S"]
                    .map(
                      (d) => Text(
                        d,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Insight",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  "You're 1,251 steps away from\nreaching your daily goal.",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textDark, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepUpNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const _StepUpNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.textDark,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarIcon(Icons.home_filled, selectedIndex == 0, () => onTap(0)),
          _NavBarIcon(
            Icons.people_rounded,
            selectedIndex == 1,
            () => onTap(1),
          ),
          _NavBarIcon(
            Icons.emoji_events_rounded,
            selectedIndex == 2,
            () => onTap(2),
          ),
          _NavBarIcon(
            Icons.auto_awesome_rounded,
            selectedIndex == 3,
            () => onTap(3),
          ),
          _NavBarIcon(Icons.person_rounded, selectedIndex == 4, () => onTap(4)),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavBarIcon(this.icon, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
        size: 24,
      ),
      onPressed: onTap,
    );
  }
}

extension IntFormatting on int {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
