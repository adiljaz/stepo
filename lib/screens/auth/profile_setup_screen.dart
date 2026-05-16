import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../cubits/auth_cubit.dart';
import '../../models/user_profile.dart';
import '../../cubits/user_settings_cubit.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEdit;
  const ProfileSetupScreen({super.key, this.isEdit = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _selectedGoal;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  final List<Map<String, dynamic>> _goals = [
    {'icon': Icons.local_fire_department_outlined, 'label': 'Lose Weight'},
    {'icon': Icons.fitness_center_outlined, 'label': 'Build Muscle'},
    {'icon': Icons.directions_run_outlined, 'label': 'Stay Fit'},
    {'icon': Icons.favorite_outline, 'label': 'Improve Health'},
  ];

  @override
  void initState() {
    super.initState();
    // Load existing data if in edit mode
    final current = context.read<UserSettingsCubit>().state;
    _nameController.text = current.name;
    _ageController.text = current.ageYears.toString();
    _heightController.text = current.heightCm.toString();
    _weightController.text = current.weightKg.toString();
    _selectedGoal = current.dailyGoalSteps >= 10000 ? 'Lose Weight' : 'Stay Fit';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleFinish() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text) ?? 25;
    final height = double.tryParse(_heightController.text) ?? 170.0;
    final weight = double.tryParse(_weightController.text) ?? 70.0;

    final profile = UserProfile(
      name: name.isNotEmpty ? name : "User",
      ageYears: age,
      heightCm: _heightUnit == 'cm' ? height : height * 30.48,
      weightKg: _weightUnit == 'kg' ? weight : weight * 0.453592,
      dailyGoalSteps: _selectedGoal == 'Lose Weight' ? 10000 : 8000,
    );

    final settingsCubit = context.read<UserSettingsCubit>();
    final authCubit = context.read<AuthCubit>();

    await settingsCubit.save(profile);
    
    if (widget.isEdit) {
      if (!mounted) return;
      context.pop();
    } else {
      authCubit.completeProfileSetup();
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/stepup_logo_footprint_1778926775481.png',
                      height: 48,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    widget.isEdit ? "Update your profile" : "Tell us about yourself",
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEdit ? "Keep your details up to date" : "Help us personalize your fitness experience",
                    style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 32),
                  
                  // Stepper (Only show in setup mode)
                  if (!widget.isEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFBFB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepperItem(Icons.person_rounded, "Personal", true),
                          _buildStepperDivider(false),
                          _buildStepperItem(Icons.track_changes_rounded, "Goals", false),
                          _buildStepperDivider(false),
                          _buildStepperItem(Icons.verified_user_rounded, "Review", false),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  
                  if (!widget.isEdit) const SizedBox(height: 40),
                  
                  // Card-like Container for Form
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: context.watch<UserSettingsCubit>().state.profileImage.isNotEmpty
                                      ? Image.network(
                                          context.read<UserSettingsCubit>().state.profileImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: const Color(0xFFF0F7ED),
                                            child: Center(
                                              child: Text(
                                                context.read<UserSettingsCubit>().state.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase(),
                                                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                              ),
                                            ),
                                          ),
                                        )
                                      : context.read<UserSettingsCubit>().state.name.isNotEmpty
                                          ? Container(
                                              color: const Color(0xFFF0F7ED),
                                              child: Center(
                                                child: Text(
                                                  context.read<UserSettingsCubit>().state.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase(),
                                                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                                ),
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/images/stepup_logo_footprint_1778926775481.png',
                                              fit: BoxFit.contain,
                                              scale: 2,
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        _buildFieldLabel("Full Name"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: "Enter your full name",
                            prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.textLight),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildFieldLabel("Age"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Enter your age",
                            prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.textLight),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildFieldLabel("Height"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Select height",
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight),
                                const SizedBox(width: 8),
                                _buildUnitToggle(_heightUnit, (val) => setState(() => _heightUnit = val), ['cm', 'ft']),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildFieldLabel("Weight"),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Select weight",
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.keyboard_arrow_down, color: AppTheme.textLight),
                                const SizedBox(width: 8),
                                _buildUnitToggle(_weightUnit, (val) => setState(() => _weightUnit = val), ['kg', 'lbs']),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text("What are your goals?", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  Text("Select your primary focus", style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final isSelected = _selectedGoal == goal['label'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGoal = goal['label'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFFBFBFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                goal['icon'] as IconData,
                                color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                goal['label'] as String,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? AppTheme.textDark : AppTheme.textLight,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _handleFinish,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.isEdit ? "Update Profile" : "Finish Setup"),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          if (widget.isEdit)
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(fontSize: 14));
  }

  Widget _buildStepperItem(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.primaryGreen : AppTheme.borderGray, width: 1.5),
            boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.2), blurRadius: 8)] : null,
          ),
          child: Icon(icon, color: isActive ? Colors.white : AppTheme.textLight, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryGreen : AppTheme.textLight,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperDivider(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen : AppTheme.borderGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildUnitToggle(String currentUnit, Function(String) onToggle, List<String> units) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.map((unit) {
          final isSelected = currentUnit == unit;
          return GestureDetector(
            onTap: () => onToggle(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
              ),
              child: Text(
                unit,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
