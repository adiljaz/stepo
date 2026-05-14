import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/background_service.dart';
import 'screens/splash_screen.dart';
import 'constants/step_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service (Stage 7 Reliability)
  await BackgroundTrackingService.initializeService();

  runApp(const ProviderScope(child: StepoooApp()));
}

class StepoooApp extends StatelessWidget {
  const StepoooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stepooo v7',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConfig.kBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.kPrimaryColor,
          primary: AppConfig.kPrimaryColor,
          surface: AppConfig.kSurfaceColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
