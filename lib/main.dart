import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'cubits/step_tracker_cubit.dart';
import 'cubits/user_settings_cubit.dart';
import 'cubits/insight_cubit.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

import 'cubits/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Service
  try {
    await BackgroundTrackingService.initializeService();
  } catch (e) {
    debugPrint("Background Service Initialization Failed: $e");
  }

  runApp(const StepoApp());
}

class StepoApp extends StatelessWidget {
  const StepoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => StepTrackerCubit()),
        BlocProvider(create: (context) => UserSettingsCubit()),
        BlocProvider(create: (context) => InsightCubit()),
      ],
      child: MaterialApp.router(
        title: 'Stepo',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
