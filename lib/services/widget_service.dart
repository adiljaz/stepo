/// Feature 8 — Android Home Screen Widget Service
///
/// Uses the `home_widget` package to push live step data to the
/// Android AppWidget (defined in res/layout/step_widget.xml).
///
/// Call [WidgetService.update] after every step batch emission.
/// The widget XML reads these keys via RemoteViews.

import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  // NOTE: home_widget automatically prepends the package name
  // (com.example.stepooo) to the class name — use ONLY the simple
  // class name here, NOT the fully-qualified name.
  static const _appWidgetProvider = 'StepWidgetProvider';

  /// Push current step data to all pinned/added home-screen widgets.
  ///
  /// [steps]    — today's committed step count
  /// [goal]     — user's daily goal (for progress calculation)
  /// [calories] — today's MET-based calorie burn
  ///
  /// All errors are silently swallowed — if no widget is pinned to the
  /// home screen, the PlatformException must not crash the pipeline.
  static Future<void> update({
    required int steps,
    required int goal,
    required double calories,
  }) async {
    try {
      final progress = goal > 0 ? (steps / goal * 100).clamp(0, 100).toInt() : 0;

      // Save each key — Android reads them via RemoteViews in StepWidgetProvider
      await Future.wait([
        HomeWidget.saveWidgetData<int>('steps', steps),
        HomeWidget.saveWidgetData<int>('goal', goal),
        HomeWidget.saveWidgetData<int>('progress', progress),
        HomeWidget.saveWidgetData<int>('calories', calories.toInt()),
      ]);

      // Trigger an Android broadcast so the widget redraws immediately
      await HomeWidget.updateWidget(
        androidName: _appWidgetProvider,
      );
    } catch (e) {
      // No widget pinned to home screen, or widget not yet registered — ignore.
      debugPrint('WidgetService: update skipped — $e');
    }
  }

  /// Call once at app start to register the widget's app group
  /// (iOS only; on Android this is a no-op but harmless).
  static Future<void> initialise() async {
    try {
      await HomeWidget.setAppGroupId('group.com.example.stepooo');
    } catch (e) {
      debugPrint('WidgetService: initialise skipped — $e');
    }
  }
}
