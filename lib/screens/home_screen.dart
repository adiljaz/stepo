import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/step_constants.dart';
import '../services/v7/step_tracking_service_v7.dart';
import '../providers/user_settings_provider.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
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
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stepTrackerProvider);
    final profile = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: IndexedStack(
        index: _selectedNav,
        children: [
          _MainDashboard(state: state, profile: profile, ringCtrl: _ringCtrl),
          const HistoryScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton:
          _selectedNav == 0
              ? FloatingActionButton.extended(
                  backgroundColor: AppConfig.kPrimaryColor,
                  icon: const Icon(Icons.directions_run_rounded, color: AppConfig.kBackgroundColor),
                  label: Text(
                    'START WORKOUT',
                    style: GoogleFonts.outfit(
                      color: AppConfig.kBackgroundColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.outfit(color: AppConfig.kPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold);
              }
              return GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontSize: 12);
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedNav,
          onDestinationSelected: (i) => setState(() => _selectedNav = i),
          backgroundColor: AppConfig.kSurfaceColor,
          indicatorColor: AppConfig.kPrimaryColor.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded, color: AppConfig.kSecondaryTextColor), 
              selectedIcon: Icon(Icons.home_rounded, color: AppConfig.kPrimaryColor), 
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded, color: AppConfig.kSecondaryTextColor), 
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppConfig.kPrimaryColor), 
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded, color: AppConfig.kSecondaryTextColor), 
              selectedIcon: Icon(Icons.settings_rounded, color: AppConfig.kPrimaryColor), 
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _MainDashboard extends StatelessWidget {
  final StepTrackerState state;
  final dynamic profile;
  final AnimationController ringCtrl;
  const _MainDashboard({required this.state, required this.profile, required this.ringCtrl});

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
                const SizedBox(height: 10),
                _NeonActivityRing(steps: state.steps, ringCtrl: ringCtrl),
                const SizedBox(height: 40),
                _sectionTitle('TODAY\'S METRICS'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _AnimatedMetricCard(title: 'DISTANCE', value: state.distanceKm, unit: 'km', icon: Icons.route_rounded, color: AppConfig.kAccentColor)),
                    const SizedBox(width: 16),
                    Expanded(child: _AnimatedMetricCard(title: 'CALORIES', value: state.calories, unit: 'kcal', icon: Icons.local_fire_department_rounded, color: AppConfig.kWarningColor)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _AnimatedMetricCard(title: 'ACTIVE TIME', value: (state.steps / 100).clamp(0, 999).toDouble(), unit: 'min', icon: Icons.timer_rounded, color: AppConfig.kPrimaryColor)),
                    const SizedBox(width: 16),
                    Expanded(child: _AnimatedMetricCard(title: 'STAIRS', value: state.flightsOfStairs.toDouble(), unit: 'flts', icon: Icons.stairs_rounded, color: AppConfig.kSuccessColor)),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      color: AppConfig.kSecondaryTextColor,
      letterSpacing: 1.5,
    ),
  );

  SliverAppBar _buildAppBar(BuildContext context) {
    final name = (profile?.name?.isNotEmpty == true) ? profile!.name : 'Athlete';
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppConfig.kBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        centerTitle: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEPOOO PRO', style: GoogleFonts.outfit(fontSize: 10, color: AppConfig.kPrimaryColor, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text(name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
          ],
        ),
      ),
    );
  }
}

class _NeonActivityRing extends StatelessWidget {
  final int steps;
  final AnimationController ringCtrl;
  const _NeonActivityRing({required this.steps, required this.ringCtrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) => Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppConfig.kSurfaceColor, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: AppConfig.kPrimaryColor.withValues(alpha: 0.15 + 0.1 * ringCtrl.value),
                    blurRadius: 50, spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: steps),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toString(), 
                    style: GoogleFonts.outfit(fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: -3, color: AppConfig.kTextColor)
                  );
                },
              ),
              Text('STEPS TODAY', style: GoogleFonts.outfit(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700, color: AppConfig.kPrimaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedMetricCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;

  const _AnimatedMetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppConfig.kSecondaryTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Text(
                    val.toStringAsFixed(title == 'DISTANCE' ? 2 : 0),
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor),
                  );
                },
              ),
              const SizedBox(width: 4),
              Text(unit, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.kSecondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }
}

