import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import '../constants/step_constants.dart';
import '../providers/step_provider.dart';
import '../services/workout_service.dart';

final _workoutProvider = ChangeNotifierProvider((_) => WorkoutService());

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  WorkoutSession? _finishedSession;

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(_workoutProvider);
    final stepState = ref.watch(stepStateProvider);

    if (_finishedSession != null) {
      return _SummaryView(session: _finishedSession!);
    }

    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      appBar: AppBar(
        backgroundColor: const Color(kBackgroundColor),
        elevation: 0,
        title: Text('Workout', style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700, fontSize: 22,
            color: const Color(kTextColor))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(kTextColor)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: workout.isActive && workout.route.isNotEmpty
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: workout.route.last,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.stepooo',
                    ),
                    PolylineLayer(polylines: [
                      Polyline(
                        points: workout.route.toList(),
                        color: const Color(kPrimaryColor),
                        strokeWidth: 5,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      if (workout.route.isNotEmpty)
                        Marker(
                          point: workout.route.last,
                          width: 24, height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(kPrimaryColor),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                    ]),
                  ],
                )
              : Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.map_rounded, size: 80,
                        color: const Color(kPrimaryColor).withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Press Start to begin tracking',
                        style: GoogleFonts.outfit(
                            color: const Color(kSecondaryTextColor))),
                  ])),
        ),
        // Stats strip
        if (workout.isActive) _StatsStrip(
          distanceKm: workout.distanceKm,
          steps: stepState.steps,
        ),
        // Action button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity, height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: workout.isActive
                    ? const Color(kErrorColor)
                    : const Color(kPrimaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (!workout.isActive) {
                  await ref.read(_workoutProvider)
                      .startWorkout(currentSteps: stepState.steps);
                } else {
                  final session = ref.read(_workoutProvider).stopWorkout();
                  setState(() => _finishedSession = session);
                }
              },
              child: Text(workout.isActive ? 'Stop Workout' : 'Start Workout',
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _Chip(label: 'Steps', value: '$steps'),
        _Chip(label: 'Distance', value: '${distanceKm.toStringAsFixed(2)} km'),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  const _Chip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: GoogleFonts.outfit(
        fontSize: 12, color: const Color(kSecondaryTextColor))),
    Text(value, style: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: const Color(kTextColor))),
  ]);
}

class _SummaryView extends StatelessWidget {
  final WorkoutSession session;
  const _SummaryView({required this.session});

  @override
  Widget build(BuildContext context) {
    final pace = session.avgPaceMinPerKm;
    final paceStr = '${pace.floor()}:${((pace % 1) * 60).round().toString().padLeft(2, '0')} /km';
    final dur = session.duration;
    final durStr = '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Workout Complete!', style: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w800,
            color: const Color(kTextColor))),
        const SizedBox(height: 24),
        // Map summary
        if (session.route.length > 1)
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: session.route.first,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.stepooo',
                  ),
                  PolylineLayer(polylines: [
                    Polyline(
                      points: session.route.toList(),
                      color: const Color(kPrimaryColor),
                      strokeWidth: 5,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _StatBox(label: 'Steps', value: '${session.steps}')),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(label: 'Distance', value: '${session.distanceKm.toStringAsFixed(2)} km')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatBox(label: 'Duration', value: durStr)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox(label: 'Avg Pace', value: paceStr)),
        ]),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(kPrimaryColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 52),
          ),
          child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ])),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(
          fontSize: 12, color: const Color(kSecondaryTextColor))),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: const Color(kTextColor))),
    ]),
  );
}
