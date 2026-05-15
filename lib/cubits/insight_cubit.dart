import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/insight_engine.dart';
import '../utils/logger.dart';

abstract class InsightState {}
class InsightLoading extends InsightState {}
class InsightLoaded extends InsightState {
  final List<Insight> insights;
  InsightLoaded(this.insights);
}
class InsightError extends InsightState {}

class InsightCubit extends Cubit<InsightState> {
  InsightCubit() : super(InsightLoading());

  Future<void> loadInsights(int dailyGoal, {bool forceRefresh = false}) async {
    try {
      emit(InsightLoading());
      AppLogger.i('InsightCubit', 'Loading insights (goal=$dailyGoal)...');
      final insights = await InsightEngine.generate(dailyGoal: dailyGoal, forceRefresh: forceRefresh);
      AppLogger.i('InsightCubit', 'Loaded ${insights.length} insights');
      emit(InsightLoaded(insights));
    } catch (e) {
      AppLogger.e('InsightCubit', 'Failed to load insights: $e');
      emit(InsightError());
    }
  }
}
