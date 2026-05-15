import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/step_tracker_cubit.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../constants/step_constants.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepTrackerCubit, StepTrackerState>(
      builder: (context, state) {
        return BlocBuilder<UserSettingsCubit, UserProfile>(
          builder: (context, profile) {
            return Scaffold(
              backgroundColor: AppConfig.kBackgroundColor,
              extendBody: true,
              body: IndexedStack(
                index: _selectedNav,
                children: [
                  _HealthDashboard(state: state, profile: profile),
                  const HistoryScreen(),
                  const SettingsScreen(),
                ],
              ),
              floatingActionButton: _selectedNav == 0
                  ? _ModernActionButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutScreen())),
                    )
                  : null,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: _ModernNavBar(
                selectedIndex: _selectedNav,
                onTap: (i) => setState(() => _selectedNav = i),
              ),
            );
          },
        );
      },
    );
  }
}

class _HealthDashboard extends StatelessWidget {
  final StepTrackerState state;
  final dynamic profile;
  const _HealthDashboard({required this.state, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = (profile?.name?.isNotEmpty == true) ? profile!.name : 'Bio-Entity';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 140,
          expandedHeight: 140,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                Positioned(
                  top: -50, right: -30,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      color: AppConfig.kPrimaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SYNCHRONIZED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.kPrimaryColor, letterSpacing: 3)),
                          const SizedBox(height: 4),
                          Text(name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, height: 1)),
                        ],
                      ),
                      const Spacer(),
                      _PulsePulse(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CyberPulseCore(steps: state.steps),
                const SizedBox(height: 40),
                Text('BIO-METRICS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppConfig.kSecondaryTextColor, letterSpacing: 2)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemBuilder: (context, index) => _CyberMetricCard(index: index, state: state),
            childCount: 4,
          ),
        ),
      ],
    );
  }
}

class _CyberPulseCore extends StatelessWidget {
  final int steps;
  const _CyberPulseCore({required this.steps});

  @override
  Widget build(BuildContext context) {
    final progress = (steps / 10000).clamp(0.0, 1.0);
    return Container(
      height: 220,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppConfig.kPrimaryColor.withValues(alpha: 0.3), Colors.transparent]),
        borderRadius: AppConfig.kOrganicRadius,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppConfig.kSurfaceColor,
          borderRadius: AppConfig.kOrganicRadius,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 20, bottom: 20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.waves_rounded, size: 100, color: AppConfig.kPrimaryColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL VITALITY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.kSecondaryTextColor, letterSpacing: 1.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppConfig.kPrimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppConfig.kPrimaryColor)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    steps.toString(),
                    style: GoogleFonts.outfit(fontSize: 72, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, height: 1, letterSpacing: -2),
                  ),
                  Text('STEPS TODAY', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppConfig.kSecondaryTextColor)),
                  const SizedBox(height: 20),
                  _CyberProgressBar(progress: progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CyberMetricCard extends StatelessWidget {
  final int index;
  final StepTrackerState state;
  const _CyberMetricCard({required this.index, required this.state});

  @override
  Widget build(BuildContext context) {
    final config = _getCardConfig(index);
    return Container(
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: AppConfig.kOrganicRadius,
        border: Border.all(color: config.color.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, color: config.color, size: 20),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(config.value, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
          ),
          Text(config.title.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.kSecondaryTextColor, letterSpacing: 1)),
        ],
      ),
    );
  }

  _CardConfig _getCardConfig(int index) {
    switch (index) {
      case 0:
        return _CardConfig(
          title: 'Distance',
          value: '${state.distanceKm.toStringAsFixed(1)} km',
          icon: Icons.route_rounded,
          color: AppConfig.kPrimaryColor,
        );
      case 1:
        return _CardConfig(
          title: 'Calories',
          value: '${state.calories.toInt()} kcal',
          icon: Icons.local_fire_department_rounded,
          color: AppConfig.kSecondaryColor,
        );
      case 2:
        return _CardConfig(
          title: 'Floors',
          value: '${state.flightsOfStairs} fl',
          icon: Icons.stairs_rounded,
          color: AppConfig.kAccentColor,
        );
      case 3:
        return _CardConfig(
          title: 'Intensity',
          value: '${(state.steps / 100).toInt()} min',
          icon: Icons.bolt_rounded,
          color: AppConfig.kSuccessColor,
        );
      default:
        return _CardConfig(title: '', value: '', icon: Icons.help, color: Colors.grey);
    }
  }
}

class _CardConfig {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _CardConfig({required this.title, required this.value, required this.icon, required this.color});
}

// --- HELPER WIDGETS ---

class _PulsePulse extends StatelessWidget {
  const _PulsePulse();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppConfig.kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConfig.kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: AppConfig.kPrimaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('LIVE PULSE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppConfig.kPrimaryColor, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _CyberProgressBar extends StatelessWidget {
  final double progress;
  const _CyberProgressBar({required this.progress});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 6,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppConfig.kPrimaryColor,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: AppConfig.kPrimaryColor.withValues(alpha: 0.5), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ModernActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 70, width: 70,
        decoration: BoxDecoration(
          color: AppConfig.kPrimaryColor,
          shape: BoxShape.circle,
          boxShadow: AppConfig.kCyberGlow(AppConfig.kPrimaryColor),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 36),
      ),
    );
  }
}

class _ModernNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const _ModernNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(Icons.grid_view_rounded, selectedIndex == 0, () => onTap(0)),
          const SizedBox(width: 48),
          _NavIcon(Icons.history_rounded, selectedIndex == 1, () => onTap(1)),
          _NavIcon(Icons.settings_rounded, selectedIndex == 2, () => onTap(2)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavIcon(this.icon, this.isSelected, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppConfig.kPrimaryColor : AppConfig.kSecondaryTextColor,
            size: 26,
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4, height: 4,
              decoration: const BoxDecoration(color: AppConfig.kPrimaryColor, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

