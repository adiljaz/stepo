import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import '../constants/step_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/workout_cubit.dart';
import '../cubits/step_tracker_cubit.dart';

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
          listener: (context, state) => _onRouteUpdate(state),
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
            backgroundColor: AppConfig.kBackgroundColor,
            appBar: AppBar(
              backgroundColor: AppConfig.kBackgroundColor,
              elevation: 0,
              title: Text(
                'WORKOUT',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 22, color: AppConfig.kTextColor),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConfig.kTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: workout.isActive && workout.route.isNotEmpty
                      ? FlutterMap(
                          mapController: _mapCtrl,
                          options: MapOptions(
                            initialCenter: workout.route.last,
                            initialZoom: 16,
                          ),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            PolylineLayer(
                              polylines: [
                                Polyline(points: workout.route, color: AppConfig.kPrimaryColor, strokeWidth: 5),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, size: 80, color: AppConfig.kPrimaryColor.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('Ready for a session?', style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                ),
                if (workout.isActive)
                  _StatsStrip(
                    distanceKm: workout.distanceKm,
                    steps: workout.currentSteps - workout.startSteps,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: workout.isActive ? AppConfig.kErrorColor : AppConfig.kPrimaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 8,
                        shadowColor: (workout.isActive ? AppConfig.kErrorColor : AppConfig.kPrimaryColor).withValues(alpha: 0.3),
                      ),
                      onPressed: () async {
                        if (!workout.isActive) {
                          final steps = context.read<StepTrackerCubit>().state.steps;
                          await context.read<WorkoutCubit>().startWorkout(currentSteps: steps);
                        } else {
                          final session = context.read<WorkoutCubit>().stopWorkout();
                          setState(() => _finishedSession = session);
                        }
                      },
                      child: Text(
                        workout.isActive ? 'STOP SESSION' : 'START SESSION',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                    ),
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

class _StatsStrip extends StatelessWidget {
  final double distanceKm;
  final int steps;
  const _StatsStrip({required this.distanceKm, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _Chip(label: 'STEPS', value: '$steps', icon: Icons.directions_walk_rounded)),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(child: _Chip(label: 'DISTANCE', value: '${distanceKm.toStringAsFixed(2)}km', icon: Icons.route_rounded)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Chip({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppConfig.kPrimaryColor),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppConfig.kSecondaryTextColor, letterSpacing: 1)),
        ],
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
      ),
    ],
  );
}

class _SummaryView extends StatelessWidget {
  final WorkoutSession session;
  const _SummaryView({required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConfig.kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded, size: 48, color: AppConfig.kPrimaryColor),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'SESSION COMPLETE',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppConfig.kTextColor),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(child: _StatBox(label: 'TOTAL STEPS', value: session.steps.toString(), color: AppConfig.kPrimaryColor)),
                const SizedBox(width: 16),
                Expanded(child: _StatBox(label: 'TOTAL KM', value: session.distanceKm.toStringAsFixed(2), color: AppConfig.kSecondaryColor)),
              ],
            ),
            const SizedBox(height: 64),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                minimumSize: const Size(double.infinity, 64),
              ),
              child: Text('FINISH', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppConfig.kSurfaceColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
        ),
      ],
    ),
  );
}
