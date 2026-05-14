import 'dart:async';
import 'package:pedometer/pedometer.dart';
import '../../utils/logger.dart';

/// STAGE 4 — SOURCE B (Hardware Step Counter).
/// 
/// Interfaces with Android TYPE_STEP_COUNTER (motion co-processor).
/// This serves as the ground truth for reconciliation.
class HardwareFusion {
  StreamSubscription<StepCount>? _pedometerSubscription;
  int? _initialHardwareSteps;
  int _currentHardwareSteps = 0;
  
  final Function(int delta) onHardwareStep;

  HardwareFusion({required this.onHardwareStep});

  void start() {
    AppLogger.i('HardwareFusion', 'Subscribing to hardware step counter...');
    _pedometerSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (e) => AppLogger.e('HardwareFusion', 'Pedometer error: $e'),
    );
  }

  void _onStepCount(StepCount event) {
    if (_initialHardwareSteps == null) {
      _initialHardwareSteps = event.steps;
      _currentHardwareSteps = 0;
      AppLogger.i('HardwareFusion', 'Hardware base set: ${event.steps}');
    } else {
      final newTotal = event.steps - _initialHardwareSteps!;
      final delta = newTotal - _currentHardwareSteps;
      
      if (delta > 0) {
        _currentHardwareSteps = newTotal;
        onHardwareStep(delta);
      }
    }
  }

  int get currentSteps => _currentHardwareSteps;

  void stop() {
    _pedometerSubscription?.cancel();
    AppLogger.i('HardwareFusion', 'Hardware fusion stopped.');
  }
}
