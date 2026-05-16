import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/workout_cubit.dart';
import '../theme/app_theme.dart';
import '../cubits/step_tracker_cubit.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutSession? _finishedSession;
  final MapController _mapCtrl = MapController();

  void _onRouteUpdate(WorkoutState workout) {
    if (workout.isActive && workout.route.isNotEmpty) {
      _mapCtrl.move(workout.route.last, _mapCtrl.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WorkoutCubit, WorkoutState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.redAccent),
              );
              context.read<WorkoutCubit>().clearError();
            }
            _onRouteUpdate(state);
          },
        ),
        BlocListener<StepTrackerCubit, StepTrackerState>(
          listener: (context, state) {
            context.read<WorkoutCubit>().updateSteps(state.steps);
          },
        ),
      ],
      child: BlocBuilder<WorkoutCubit, WorkoutState>(
        builder: (context, workout) {
          if (_finishedSession != null) {
            return _SummaryView(session: _finishedSession!);
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Map Background
                Positioned.fill(
                  child: workout.isActive && workout.route.isNotEmpty
                      ? FlutterMap(
                          mapController: _mapCtrl,
                          options: MapOptions(
                            initialCenter: workout.route.last,
                            initialZoom: 16,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: workout.route,
                                  color: AppTheme.primaryGreen,
                                  strokeWidth: 5,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(color: const Color(0xFFF8FAF8)),
                ),

                // Top Header Overlay
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20, right: 20,
                  child: Row(
                    children: [
                      _BlurButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      if (workout.isActive) _ChallengeProgressHeader(),
                    ],
                  ),
                ),

                // Bottom Stats Card
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _BottomActivityCard(
                    workout: workout,
                    onStop: (session) {
                      setState(() => _finishedSession = session);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BlurButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BlurButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.textDark, size: 20),
      ),
    );
  }
}

class _ChallengeProgressHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<UserSettingsCubit, UserProfile>(
            builder: (context, profile) {
              final userName = profile.name;
              return profile.profileImage.isNotEmpty 
                ? _MiniAvatar(url: profile.profileImage)
                : CircleAvatar(
                    radius: 12, 
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1), 
                    child: Text(
                      userName.isNotEmpty ? userName[0] : 'U', 
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)
                    ),
                  );
            },
          ),
          const SizedBox(width: 8),
          Text("VS", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textLight)),
          const SizedBox(width: 8),
          _MiniAvatar(url: 'https://i.pravatar.cc/100?u=2'),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("10K Steps Battle", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              BlocBuilder<StepTrackerCubit, StepTrackerState>(
                builder: (context, state) {
                  final diff = state.steps - 8649;
                  return Text(
                    diff >= 0 ? "Leading by ${diff.abs()}" : "Trailing by ${diff.abs()}", 
                    style: GoogleFonts.outfit(fontSize: 9, color: diff >= 0 ? AppTheme.primaryGreen : Colors.red, fontWeight: FontWeight.bold)
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String url;
  const _MiniAvatar({required this.url});
  @override
  Widget build(BuildContext context) => CircleAvatar(radius: 12, backgroundImage: NetworkImage(url));
}

class _BottomActivityCard extends StatelessWidget {
  final WorkoutState workout;
  final Function(WorkoutSession) onStop;
  const _BottomActivityCard({required this.workout, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final steps = workout.isActive ? workout.currentSteps - workout.startSteps : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (workout.isActive) ...[
            Text("YOU ARE LEADING! 🏆", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 16),
            Text(steps.toString(), style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
            Text("STEPS TAKEN", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight, letterSpacing: 1)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _WorkoutMetric(label: "Distance", value: "${workout.distanceKm.toStringAsFixed(2)} km"),
                _WorkoutMetric(label: "Calories", value: "${(steps * 0.04).toStringAsFixed(1)} kcal"),
                _WorkoutMetric(label: "Time", value: "14:23"),
              ],
            ),
          ] else
            Text("READY TO GO?", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () async {
                if (!workout.isActive) {
                  final steps = context.read<StepTrackerCubit>().state.steps;
                  await context.read<WorkoutCubit>().startWorkout(currentSteps: steps);
                } else {
                  final session = context.read<WorkoutCubit>().stopWorkout();
                  onStop(session);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: workout.isActive ? Colors.red : AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                workout.isActive ? "STOP SESSION" : "START SESSION",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  final String label, value;
  const _WorkoutMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  final WorkoutSession session;
  const _SummaryView({required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration_rounded, size: 80, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            Text("Session Complete!", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryStat(label: "Steps", value: session.steps.toString()),
                const SizedBox(width: 40),
                _SummaryStat(label: "Distance", value: "${session.distanceKm.toStringAsFixed(2)} km"),
              ],
            ),
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("Back to Home", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  const _SummaryStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
