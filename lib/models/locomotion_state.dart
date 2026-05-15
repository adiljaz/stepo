enum VehicleType {
  car,
  bus,
  rail,
  cycling,
  none,
}

sealed class LocomotionState {
  const LocomotionState();
}

class StationaryState extends LocomotionState {
  const StationaryState();
}

class WalkingState extends LocomotionState {
  const WalkingState();
}

class RunningState extends LocomotionState {
  const RunningState();
}

class CyclingState extends LocomotionState {
  final double cadenceRpm;
  const CyclingState({this.cadenceRpm = 0});
}

class InVehicleState extends LocomotionState {
  final VehicleType vehicleType;
  final double confidence;
  const InVehicleState(this.vehicleType, {this.confidence = 1.0});
}

class AmbiguousState extends LocomotionState {
  final String reason;
  const AmbiguousState(this.reason);
}

class SuspiciousMovementState extends LocomotionState {
  final String violation;
  const SuspiciousMovementState(this.violation);
}
