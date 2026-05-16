import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../cubits/auth_cubit.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Full name is required';
    if (value.length < 2) return 'Enter a valid name';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _handleGoogleLogin() async {
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
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/profile-setup');
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Signup failed"),
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
                  height: 180,
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
                
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Top Navigation / Logo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                                onPressed: () => context.pop(),
                              ),
                              TextButton(
                                onPressed: () => context.push('/login'),
                                child: const Text("Login", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        
                        // Center Logo
                        Image.asset(
                          'assets/images/stepup_logo_footprint_1778926775481.png',
                          height: 48,
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          "Create your account",
                          style: theme.textTheme.displayLarge?.copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          "Start your journey today",
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Signup Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel("Full Name"),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  validator: _validateName,
                                  decoration: const InputDecoration(
                                    hintText: "Enter your full name",
                                    prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.textLight),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildFieldLabel("Email Address"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: "Enter your email",
                                    prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.textLight),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildFieldLabel("Password"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: "Create a password",
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textLight),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppTheme.textLight,
                                      ),
                                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildFieldLabel("Confirm Password"),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  validator: _validateConfirmPassword,
                                  obscureText: !_isConfirmPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: "Confirm your password",
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textLight),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppTheme.textLight,
                                      ),
                                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Password Requirements Chips (Live validation)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7FBF7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildRequirementChip("At least 8 characters", _passwordController.text.length >= 8),
                                      const SizedBox(height: 6),
                                      _buildRequirementChip("Include a number", _passwordController.text.contains(RegExp(r'[0-9]'))),
                                      const SizedBox(height: 6),
                                      _buildRequirementChip("Include an uppercase letter", _passwordController.text.contains(RegExp(r'[A-Z]'))),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                ElevatedButton(
                                  onPressed: isLoading ? null : _handleSignUp,
                                  child: isLoading 
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("Sign Up"),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 20),
                                        ],
                                      ),
                                ),
                                
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: AppTheme.borderGray, thickness: 1)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text("OR", style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(child: Divider(color: AppTheme.borderGray, thickness: 1)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                OutlinedButton(
                                  onPressed: isLoading ? null : _handleGoogleLogin,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png', 
                                        height: 24,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text("Continue with Google"),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "By signing up, you agree to our",
                                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Terms of Service",
                                            style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                          ),
                                          Text(" and ", style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                                          Text(
                                            "Privacy Policy",
                                            style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
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

  Widget _buildFieldLabel(String label) {
    return Text(label, style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(fontSize: 14));
  }

  Widget _buildRequirementChip(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: isMet ? AppTheme.primaryGreen : AppTheme.textLight.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isMet ? AppTheme.textDark : AppTheme.textLight,
            fontSize: 13,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
