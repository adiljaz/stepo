import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

enum HealthSyncStatus { connected, disconnected, error }

class HealthSyncService {
  final Health _health = Health();
  int _lastSyncedSteps = 0;
  DateTime _lastSyncTime = DateTime.now();

  Future<bool> requestPermissions() async {
    try {
      // Check if Health Connect is installed/available
      if (await Health().getHealthConnectSdkStatus() != HealthConnectSdkStatus.sdkAvailable) {
        debugPrint('Health Connect is not available on this device.');
        return false;
      }

      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ_WRITE];
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      debugPrint('Health authorization failed: $e');
      return false;
    }
  }

  Future<void> syncSteps(int currentSteps) async {
    final stepDelta = currentSteps - _lastSyncedSteps;
    if (stepDelta <= 0) return;

    try {
      final now = DateTime.now();
      final success = await _health.writeHealthData(
        value: stepDelta.toDouble(),
        type: HealthDataType.STEPS,
        startTime: _lastSyncTime,
        endTime: now,
      );
      
      if (success) {
        _lastSyncedSteps = currentSteps;
        _lastSyncTime = now;
      }
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }
  }
}
