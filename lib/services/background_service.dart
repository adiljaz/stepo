// ════════════════════════════════════════════════════════════════════════════
// background_service.dart — High-Availability Tracking Isolate
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
class BackgroundTrackingService {
  static Future<void> initializeService() async {
    try {
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    } catch (e) {
      debugPrint('Background service initialization failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    int currentSteps = 0;
    int goalSteps = 10000;
    String locomotion = "Stationary";

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      service.on('updateNotification').listen((event) {
        if (event != null) {
          currentSteps = event['steps'] ?? currentSteps;
          goalSteps = event['goal'] ?? goalSteps;
          locomotion = event['locomotion'] ?? locomotion;
          final double distance = (event['distance'] as num?)?.toDouble() ?? 0.0;
          final double calories = (event['calories'] as num?)?.toDouble() ?? 0.0;
          
          final progress = (currentSteps / goalSteps).clamp(0.0, 1.0);
          final bar = _generateColorfulBar(progress);
          final percent = (progress * 100).toInt();
          
          service.setForegroundNotificationInfo(
            title: "𝕊𝕋𝔼ℙ𝕆𝕆𝕆 ℙℝ𝕆 — $locomotion",
            content: "$bar  $percent%\n"
                     "🏃 $currentSteps steps  |  🏁 $goalSteps goal\n"
                     "⚡ ${distance.toStringAsFixed(2)} KM  |  🔥 ${calories.toStringAsFixed(0)} KCAL",
          );
        }
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Background logic loop
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      service.invoke('update', {
        "current_date": DateTime.now().toIso8601String(),
      });
    });
  }

  static String _generateColorfulBar(double progress) {
    const int totalBlocks = 12;
    final int filledBlocks = (progress * totalBlocks).round();
    final buffer = StringBuffer("");
    
    for (int i = 0; i < totalBlocks; i++) {
      if (i < filledBlocks) {
        buffer.write("🟩"); // Green for filled
      } else {
        buffer.write("⬜"); // White for empty
      }
    }
    return buffer.toString();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
