import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth_cubit.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Perform auth check
    await context.read<AuthCubit>().checkAuth();
    
    // Minimum splash duration
    await Future.delayed(2500.ms);
    
    if (mounted) {
      final state = context.read<AuthCubit>().state;
      _navigate(state.status);
    }
  }

  void _navigate(AuthStatus status) {
    switch (status) {
      case AuthStatus.onboardingRequired:
        context.go('/onboarding');
        break;
      case AuthStatus.authenticated:
        context.go('/home');
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      default:
        context.go('/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // StepUp Logo with Animation
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/stepup_logo_footprint_1778926775481.png',
                    height: 100,
                  ),
                ).animate()
                 .fadeIn(duration: 800.ms)
                 .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                Text(
                  "STEP UP",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: 4,
                  ),
                ).animate()
                 .fadeIn(delay: 400.ms)
                 .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  "Your Movement, Perfected",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate()
                 .fadeIn(delay: 600.ms),
              ],
            ),
          ),
          
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFF0F0F0),
                  color: AppTheme.primaryGreen,
                  minHeight: 2,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }
}
