import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/background_service.dart';
import 'screens/splash_screen.dart';
import 'constants/step_constants.dart';
import 'models/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/user_settings_cubit.dart';
import 'cubits/step_tracker_cubit.dart';
import 'cubits/workout_cubit.dart';
import 'cubits/insight_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTrackingService.initializeService();

  runApp(const StepoooApp());
}

class StepoooApp extends StatelessWidget {
  const StepoooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserSettingsCubit()),
        BlocProvider(create: (_) => StepTrackerCubit()),
        BlocProvider(create: (_) => WorkoutCubit()),
        BlocProvider(create: (_) => InsightCubit()),
      ],
      child: BlocListener<UserSettingsCubit, UserProfile>(
        listener: (context, profile) {
          context.read<StepTrackerCubit>().updateProfile(profile);
          context.read<InsightCubit>().loadInsights(profile.dailyGoalSteps);
        },
        child: MaterialApp(
          title: 'Stepooo v7',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppConfig.kBackgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConfig.kPrimaryColor,
              primary: AppConfig.kPrimaryColor,
              secondary: AppConfig.kSecondaryColor,
              surface: AppConfig.kSurfaceColor,
              error: AppConfig.kErrorColor,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.outfitTextTheme(
              ThemeData.dark().textTheme,
            ).apply(
              bodyColor: AppConfig.kTextColor,
              displayColor: AppConfig.kTextColor,
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
