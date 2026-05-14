import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_service.dart';

final workoutProvider = ChangeNotifierProvider((ref) => WorkoutService());
