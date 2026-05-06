import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/step_tracking_service.dart';

/// Global singleton provider for [StepTrackingService].
///
/// Riverpod ensures the service is created once and disposed when no longer
/// needed. All UI widgets consume state via [stepStateProvider].
final stepTrackingProvider = StateNotifierProvider<StepTrackingService, StepTrackingState>(
  (ref) {
    return StepTrackingService();
  },
);

/// Convenience provider that exposes the current [StepTrackingState] snapshot.
final stepStateProvider = Provider<StepTrackingState>((ref) {
  return ref.watch(stepTrackingProvider);
});
