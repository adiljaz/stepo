import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';
import '../models/user_profile.dart';
import 'home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_settings_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _nameCtrl = TextEditingController();
  int _age = 28;
  double _weight = 70;
  double _height = 170;
  String _sex = 'male';
  int _goal = 8000;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutQuart);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Athlete' : _nameCtrl.text.trim(),
      ageYears: _age,
      weightKg: _weight,
      heightCm: _height,
      sex: _sex,
      dailyGoalSteps: _goal,
    );
    await context.read<UserSettingsCubit>().save(profile);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppConfig.kPrimaryColor : AppConfig.kPrimaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(nameCtrl: _nameCtrl),
                  _BodyPage(
                    age: _age, weight: _weight, height: _height, sex: _sex,
                    onChanged: (age, weight, height, sex) => setState(() {
                      _age = age; _weight = weight;
                      _height = height; _sex = sex;
                    }),
                  ),
                  _GoalPage(goal: _goal, onChanged: (v) => setState(() => _goal = v)),
                  _ReadyPage(name: _nameCtrl.text.trim().isEmpty ? 'Athlete' : _nameCtrl.text.trim()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: AppConfig.kPrimaryColor.withValues(alpha: 0.4),
                  ),
                  onPressed: _next,
                  child: Text(
                    _page < 3 ? 'Continue' : 'Start My Journey',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final TextEditingController nameCtrl;
  const _WelcomePage({required this.nameCtrl});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: AppConfig.kPrimaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, size: 64, color: AppConfig.kPrimaryColor),
          ),
          const SizedBox(height: 40),
          Text('Your AI Coach Awaits', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, letterSpacing: -1)),
          const SizedBox(height: 16),
          Text('Experience research-grade step tracking calibrated specifically to your movement profile.', 
            textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, color: AppConfig.kSecondaryTextColor)),
          const SizedBox(height: 48),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: AppConfig.kSurfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.person_rounded, color: AppConfig.kPrimaryColor),
            ),
            style: GoogleFonts.outfit(fontSize: 18, color: AppConfig.kTextColor),
          ),
        ],
      ),
    );
  }
}

class _BodyPage extends StatelessWidget {
  final int age; final double weight, height; final String sex;
  final void Function(int, double, double, String) onChanged;
  const _BodyPage({required this.age, required this.weight, required this.height, required this.sex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 20),
        Text('Your Stats', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text('We use these to calculate metabolic burn with precision.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor)),
        const SizedBox(height: 40),
        _SliderCard(label: 'Age', value: age.toDouble(), min: 10, max: 90, unit: 'yrs', onChanged: (v) => onChanged(v.round(), weight, height, sex)),
        const SizedBox(height: 20),
        _SliderCard(label: 'Weight', value: weight, min: 30, max: 180, unit: 'kg', onChanged: (v) => onChanged(age, v, height, sex)),
        const SizedBox(height: 20),
        _SliderCard(label: 'Height', value: height, min: 120, max: 220, unit: 'cm', onChanged: (v) => onChanged(age, weight, v, sex)),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: _SexButton(label: 'Male', selected: sex == 'male', onTap: () => onChanged(age, weight, height, 'male'))),
          const SizedBox(width: 16),
          Expanded(child: _SexButton(label: 'Female', selected: sex == 'female', onTap: () => onChanged(age, weight, height, 'female'))),
        ]),
      ]),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _SliderCard({required this.label, required this.value, required this.min, required this.max, required this.unit, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppConfig.kSurfaceColor, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppConfig.kSecondaryTextColor)),
          Text('${value.toStringAsFixed(0)} $unit', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppConfig.kPrimaryColor)),
        ]),
        const SizedBox(height: 8),
        Slider(value: value, min: min, max: max, activeColor: AppConfig.kPrimaryColor, inactiveColor: AppConfig.kPrimaryColor.withValues(alpha: 0.1), onChanged: onChanged),
      ]),
    );
  }
}

class _SexButton extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _SexButton({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppConfig.kPrimaryColor : AppConfig.kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [BoxShadow(color: AppConfig.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
        ),
        child: Center(child: Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppConfig.kTextColor))),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final int goal; final ValueChanged<int> onChanged;
  const _GoalPage({required this.goal, required this.onChanged});

  static const List<Map<String, dynamic>> _presets = [
    {'label': 'Moderate', 'steps': 8000, 'desc': 'Healthy daily habit'},
    {'label': 'Active', 'steps': 10000, 'desc': 'Fitness enthusiast'},
    {'label': 'Athlete', 'steps': 15000, 'desc': 'High performance'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Daily Goal', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, letterSpacing: -1)),
          const SizedBox(height: 12),
          Text('How many steps do you want to conquer?', style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor)),
          const SizedBox(height: 48),
          ..._presets.map((p) {
            final selected = goal == p['steps'] as int;
            return GestureDetector(
              onTap: () => onChanged(p['steps'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: selected ? AppConfig.kPrimaryColor : AppConfig.kSurfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected ? [BoxShadow(color: AppConfig.kPrimaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['label'] as String, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppConfig.kTextColor)),
                    Text(p['desc'] as String, style: GoogleFonts.outfit(fontSize: 14, color: selected ? Colors.white70 : AppConfig.kSecondaryTextColor)),
                  ])),
                  Text('${((p['steps'] as int) / 1000).toInt()}K', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: selected ? Colors.white : AppConfig.kPrimaryColor)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  final String name;
  const _ReadyPage({required this.name});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.verified_user_rounded, size: 100, color: AppConfig.kSuccessColor),
        const SizedBox(height: 40),
        Text('Ready, $name!', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: AppConfig.kTextColor, letterSpacing: -1)),
        const SizedBox(height: 20),
        Text('Your health engine has been calibrated and is ready to track your every move.', 
          textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, color: AppConfig.kSecondaryTextColor, height: 1.5)),
      ]),
    );
  }
}
