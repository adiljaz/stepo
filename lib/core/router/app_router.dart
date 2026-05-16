import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/auth/profile_setup_screen.dart';
import '../../screens/home_screen.dart';
import '../../cubits/auth_cubit.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final status = authState.status;
    final location = state.matchedLocation;

    // Splash logic
    if (status == AuthStatus.initial && location != '/splash') return '/splash';
    
    // Auth logic
    if (status == AuthStatus.unauthenticated) {
      if (location == '/login' || location == '/register') return null;
      return '/login';
    }

    // Profile setup logic (only show once)
    if (status == AuthStatus.profileSetupRequired && location != '/profile-setup') {
      return '/profile-setup';
    }

    // Prevent access to auth screens if authenticated
    if (status == AuthStatus.authenticated && (location == '/login' || location == '/register' || location == '/profile-setup')) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) {
        final isEdit = state.uri.queryParameters['edit'] == 'true';
        return ProfileSetupScreen(isEdit: isEdit);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
