// ════════════════════════════════════════════════════════════════════════════
// insight_provider.dart — Riverpod Provider for InsightEngine
// ════════════════════════════════════════════════════════════════════════════
//
// Exposes the [InsightEngine] result as an [AsyncNotifierProvider] so the
// [InsightCarousel] can reactively load and refresh insights.
//
// Insights are refreshed daily (cached in SharedPreferences).
// Call [ref.invalidate(insightProvider)] to force an immediate refresh,
// e.g. after a new daily record is saved.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/insight_engine.dart';
import '../providers/user_settings_provider.dart';
import '../utils/logger.dart';

/// [AsyncNotifier] that wraps [InsightEngine.generate].
class InsightNotifier extends AsyncNotifier<List<Insight>> {
  @override
  Future<List<Insight>> build() async {
    // Read the user's daily goal from settings to power goal-hit insights
    final settings = ref.watch(userSettingsProvider);
    final goal = settings.dailyGoalSteps;

    AppLogger.i('InsightProvider', 'Loading insights (goal=$goal)...');
    final insights = await InsightEngine.generate(dailyGoal: goal);
    AppLogger.i('InsightProvider', 'Loaded ${insights.length} insights');
    return insights;
  }

  /// Force a fresh computation ignoring the cache.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final settings = ref.read(userSettingsProvider);
    final goal = settings.dailyGoalSteps;
    state = await AsyncValue.guard(
      () => InsightEngine.generate(dailyGoal: goal, forceRefresh: true),
    );
  }
}

/// Top-level provider consumed by [InsightCarousel].
final insightProvider =
    AsyncNotifierProvider<InsightNotifier, List<Insight>>(
  InsightNotifier.new,
);
