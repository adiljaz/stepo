import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:stepooo/services/workout_service.dart';
import '../constants/step_constants.dart';
import '../services/v7/step_tracking_service_v7.dart';
import '../providers/workout_provider.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  WorkoutSession? _finishedSession;
  final MapController _mapCtrl = MapController();

  void _onRouteUpdate(WorkoutService workout) {
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
    final workout = ref.watch(workoutProvider);
    final stepState = ref.watch(stepTrackerProvider);

    if (workout.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workoutProvider).updateSteps(stepState.steps);
      });
    }

    ref.listen(workoutProvider, (_, next) => _onRouteUpdate(next));

    if (_finishedSession != null) {
      return _SummaryView(session: _finishedSession!);
    }

    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.kBackgroundColor,
        elevation: 0,
        title: Text(
          'Workout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 22, color: AppConfig.kTextColor),
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
                          Polyline(points: workout.route.toList(), color: AppConfig.kPrimaryColor, strokeWidth: 5),
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
                        Text('Press Start to begin tracking', style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor)),
                      ],
                    ),
                  ),
          ),
          if (workout.isActive)
            _StatsStrip(
              distanceKm: workout.distanceKm,
              steps: stepState.steps - (workout.startSteps ?? stepState.steps),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: workout.isActive ? AppConfig.kErrorColor : AppConfig.kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  if (!workout.isActive) {
                    await ref.read(workoutProvider).startWorkout(currentSteps: stepState.steps);
                  } else {
                    final session = ref.read(workoutProvider).stopWorkout();
                    setState(() => _finishedSession = session);
                  }
                },
                child: Text(workout.isActive ? 'Stop Workout' : 'Start Workout', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
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
      color: AppConfig.kSurfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Chip(label: 'Steps', value: '$steps'),
          _Chip(label: 'Distance', value: '${distanceKm.toStringAsFixed(2)} km'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  const _Chip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor)),
      Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppConfig.kTextColor)),
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
          padding: const EdgeInsets.all(24),
          children: [
            Text('Workout Complete!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Steps', value: '${session.steps}')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(label: 'Distance', value: '${session.distanceKm.toStringAsFixed(2)} km')),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.kPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppConfig.kSurfaceColor, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppConfig.kTextColor)),
      ],
    ),
  );
}
