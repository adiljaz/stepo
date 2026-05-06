import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/step_constants.dart';
import '../providers/step_provider.dart';
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
      duration: const Duration(milliseconds: 1200),
    );
    _fadeLogo = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _scaleLogo = Tween<double>(begin: 0.8, end: 1.0).animate(
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

    Future.delayed(const Duration(milliseconds: kSplashMinDurationMs), () {
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
      final service = ref.read(stepTrackingProvider.notifier);
      await service.initialise();
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
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      body: Stack(
        children: [
          // Subtle background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(kPrimaryColor).withOpacity(0.05),
                    const Color(kBackgroundColor),
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
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(kPrimaryColor).withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_run_rounded,
                          size: 72,
                          color: Color(kPrimaryColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _fadeText,
                  child: SlideTransition(
                    position: _slideText,
                    child: Column(
                      children: [
                        Text(
                          'Stepooo',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: const Color(kTextColor),
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PREMIUM MOTION ENGINE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(kPrimaryColor).withOpacity(0.6),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Version at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeText,
                child: Text(
                  'Version 4.0.0 (Zero-Delay)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(kSecondaryTextColor),
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
