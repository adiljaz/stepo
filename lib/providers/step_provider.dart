import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/v7/step_tracking_service_v7.dart';

/// Global singleton provider for the v7.0 Biomechanical Engine.
final stepTrackerProvider = StateNotifierProvider<StepTrackingServiceV7, StepTrackerState>(
  (ref) => StepTrackingServiceV7(),
);

/// Convenience provider for the UI to watch the latest AI tracking state.
final stepStateProvider = Provider<StepTrackerState>((ref) {
  return ref.watch(stepTrackerProvider);
});
