import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/step_constants.dart';
import '../services/v7/step_tracking_service_v7.dart';
import '../providers/user_settings_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _scaleLogo;

  late final AnimationController _textCtrl;
  late final Animation<double> _fadeText;
  late final Animation<Offset> _slideText;

  bool _permissionsDone = false;
  bool _minTimeDone = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeLogo = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _scaleLogo = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 1.0, curve: Curves.elasticOut)),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeText = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _slideText = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );

    _logoCtrl.forward().then((_) => _textCtrl.forward());

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _minTimeDone = true;
        _attemptNavigation();
      }
    });

    _requestPermissions();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.activityRecognition,
      Permission.locationWhenInUse,
      Permission.sensors,
    ].request();

    if (mounted) {
      // v7.0 Engine Warmup
      await ref.read(stepTrackerProvider.notifier).initialize();
      _permissionsDone = true;
      _attemptNavigation();
    }
  }

  void _attemptNavigation() async {
    if (_permissionsDone && _minTimeDone && mounted) {
      final onboarded = await UserSettingsNotifier.isOnboarded();
      if (!mounted) return;
      final destination = onboarded ? const HomeScreen() : const OnboardingScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppConfig.kPrimaryColor.withValues(alpha: 0.15),
                    AppConfig.kBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleLogo,
                  child: FadeTransition(
                    opacity: _fadeLogo,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppConfig.kSurfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConfig.kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_run_rounded,
                          size: 80,
                          color: AppConfig.kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 54),
                FadeTransition(
                  opacity: _fadeText,
                  child: SlideTransition(
                    position: _slideText,
                    child: Column(
                      children: [
                        Text(
                          'Stepooo',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppConfig.kTextColor,
                            letterSpacing: -2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v7.0 AI BIOMECHANICAL ENGINE',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppConfig.kAccentColor.withValues(alpha: 0.8),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeText,
                child: Text(
                  'RESEARCH GRADE MOTION TRACKING',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppConfig.kSecondaryTextColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
