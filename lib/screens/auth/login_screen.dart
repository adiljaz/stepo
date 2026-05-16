import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../cubits/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _handleGoogleLogin() async {
    // Keeping this for now as a direct service call or move to Cubit later
    setState(() => _isLoading = true);
    final success = await _authService.signIn();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google Sign-In failed."),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/home');
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Authentication failed"),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading || _isLoading;
            return Stack(
              children: [
                // Bottom Landscape Graphic
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 150,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                        stops: [0.0, 0.4],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      'assets/images/stepup_bottom_landscape_1778926749393.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Runner Image in Background
                Positioned(
                  top: 40,
                  right: -20,
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/images/stepup_login_header_runner_1778926718311.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

                // Content
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section - more compact
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/stepup_logo_footprint_1778926775481.png',
                                    height: 32,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "StepUp",
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),

                              // Welcome Section - image removed from here, now in background
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    "Welcome back! 👋",
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 28,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Login to continue your journey",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: AppTheme.textDark.withValues(alpha: 0.7),
                                    ),
                                  ).animate().fadeIn(delay: 200.ms),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Form Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Field
                                Text(
                                  "Email Address",
                                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: "Enter your email",
                                    prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppTheme.textLight),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Password Field
                                Text(
                                  "Password",
                                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: "Enter your password",
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.textLight),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: AppTheme.textLight,
                                      ),
                                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!.validate()) {
                                            context.read<AuthCubit>().login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                          }
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("Login"),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward, size: 18),
                                          ],
                                        ),
                                ),

                                const SizedBox(height: 16),
                                
                                // Google Auth - Moved higher for first look visibility
                                OutlinedButton(
                                  onPressed: isLoading ? null : _handleGoogleLogin,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                                        height: 20,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text("Continue with Google", style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                                        children: const [
                                          TextSpan(
                                            text: "Sign up",
                                            style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer Icons Section - more compact
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFooterItem(Icons.bar_chart_rounded, "Track Progress", "Monitor your\nsteps"),
                              _buildFooterItem(Icons.emoji_events_outlined, "Join Challenges", "Compete with\nfriends"),
                              _buildFooterItem(Icons.energy_savings_leaf_outlined, "Stay Healthy", "Build better\nhabits"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: AppTheme.textLight.withValues(alpha: 0.7), height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
