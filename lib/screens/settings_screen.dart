import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stepooo/cubits/step_tracker_cubit.dart';
import 'package:stepooo/utils/int_formatting.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';
import '../cubits/auth_cubit.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserSettingsCubit, UserProfile>(
      builder: (context, profile) {
        final name = profile.name.isNotEmpty ? profile.name : "User";
        final initials =
            name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join('')
                .toUpperCase();
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Profile",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppTheme.textDark,
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Profile Header
                Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                          ),
                        ],
                        image:
                            profile.profileImage.isNotEmpty
                                ? DecorationImage(
                                  image: NetworkImage(profile.profileImage),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          profile.profileImage.isEmpty
                              ? Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      profile.sex.isNotEmpty
                          ? "${profile.sex.toUpperCase()} · ${profile.ageYears} years"
                          : "Profile Details",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Level Progress
                _LevelCard(),

                const SizedBox(height: 24),

                // Stats Grid
                BlocBuilder<StepTrackerCubit, StepTrackerState>(
                  builder: (context, trackerState) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ProfileStat(
                          label: "Steps",
                          value: trackerState.steps.toLocaleString(),
                        ),
                        _ProfileStat(
                          label: "Distance",
                          value:
                              "${trackerState.distanceKm.toStringAsFixed(1)} km",
                        ),
                        _ProfileStat(
                          label: "Calories",
                          value: "${trackerState.calories.toInt()} kcal",
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                _ProfileOption(
                  icon: Icons.person_outline_rounded,
                  label: "Edit Personal Details",
                  onTap: () => context.push('/profile-setup?edit=true'),
                ),
                _ProfileOption(
                  icon: Icons.emoji_events_outlined,
                  label: "Achievements",
                ),
                _ProfileOption(
                  icon: Icons.star_outline_rounded,
                  label: "Personal Bests",
                ),
                _ProfileOption(
                  icon: Icons.track_changes_rounded,
                  label: "Goals",
                ),
                _ProfileOption(
                  icon: Icons.favorite_outline_rounded,
                  label: "Health Data",
                ),
                _ProfileOption(
                  icon: Icons.history_rounded,
                  label: "Leaderboard History",
                ),
                _ProfileOption(
                  icon: Icons.people_outline_rounded,
                  label: "Friends",
                ),

                const SizedBox(height: 32),

                // Logout
                ListTile(
                  onTap: () async {
                    await context.read<AuthCubit>().logout();
                    if (!context.mounted) return;
                    context.go('/splash');
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Logout",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Level 15",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "12,450 XP to next level",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 6,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label, value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
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

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ProfileOption({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.textDark, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textLight,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
