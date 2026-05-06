import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/background_service.dart';
import 'screens/splash_screen.dart';
import 'constants/step_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Service (Layer 7)
  await BackgroundTrackingService.initializeService();

  runApp(const ProviderScope(child: StepoooApp()));
}

class StepoooApp extends StatelessWidget {
  const StepoooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stepooo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(kPrimaryColor),
          primary: const Color(kPrimaryColor),
          surface: const Color(kBackgroundColor),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
