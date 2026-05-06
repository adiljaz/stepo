import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';
import '../models/user_profile.dart';
import '../providers/user_settings_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Form state
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
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
    await ref.read(userSettingsProvider.notifier).save(profile);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: const Color(kBackgroundColor),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? const Color(kPrimaryColor)
                        : const Color(kPrimaryColor).withValues(alpha: 0.2),
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
                  _GoalPage(
                    goal: _goal,
                    onChanged: (v) => setState(() => _goal = v),
                  ),
                  _ReadyPage(name: _nameCtrl.text.trim().isEmpty ? 'Athlete' : _nameCtrl.text.trim()),
                ],
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset > 0 ? 12 : 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(kPrimaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _next,
                  child: Text(
                    _page < 3 ? 'Continue' : 'Let\'s Go!',
                    style: GoogleFonts.outfit(
                        fontSize: 17, fontWeight: FontWeight.w700),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: const Color(kPrimaryColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_run_rounded,
                size: 48, color: Color(kPrimaryColor)),
          ),
          const SizedBox(height: 24),
          Text('Welcome to Stepooo', style: GoogleFonts.outfit(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: const Color(kTextColor))),
          const SizedBox(height: 10),
          Text('Let\'s personalize your experience. What should we call you?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15,
                  color: const Color(kSecondaryTextColor))),
          const SizedBox(height: 28),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              hintText: 'Your name (optional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            style: GoogleFonts.outfit(fontSize: 16),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _BodyPage extends StatelessWidget {
  final int age; final double weight, height; final String sex;
  final void Function(int, double, double, String) onChanged;
  const _BodyPage({required this.age, required this.weight,
      required this.height, required this.sex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        const SizedBox(height: 16),
        Text('Your Profile', style: GoogleFonts.outfit(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: const Color(kTextColor))),
        const SizedBox(height: 8),
        Text('Used for accurate MET-based calorie calculation',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(kSecondaryTextColor))),
        const SizedBox(height: 32),
        _SliderCard(
          label: 'Age', value: age.toDouble(), min: 10, max: 90, divisions: 80,
          unit: 'yrs', onChanged: (v) => onChanged(v.round(), weight, height, sex),
        ),
        const SizedBox(height: 16),
        _SliderCard(
          label: 'Weight', value: weight, min: 30, max: 200, divisions: 170,
          unit: 'kg', onChanged: (v) => onChanged(age, v, height, sex),
        ),
        const SizedBox(height: 16),
        _SliderCard(
          label: 'Height', value: height, min: 100, max: 230, divisions: 130,
          unit: 'cm', onChanged: (v) => onChanged(age, weight, v, sex),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _SexButton(label: 'Male', selected: sex == 'male',
              onTap: () => onChanged(age, weight, height, 'male'))),
          const SizedBox(width: 12),
          Expanded(child: _SexButton(label: 'Female', selected: sex == 'female',
              onTap: () => onChanged(age, weight, height, 'female'))),
        ]),
      ]),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const _SliderCard({required this.label, required this.value, required this.min,
      required this.max, required this.divisions, required this.unit, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: const Color(kSecondaryTextColor))),
          Text('${value.toStringAsFixed(label == 'Age' ? 0 : 1)} $unit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                  color: const Color(kPrimaryColor))),
        ]),
        Slider(value: value, min: min, max: max, divisions: divisions,
            activeColor: const Color(kPrimaryColor), onChanged: onChanged),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(kPrimaryColor) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected
              ? const Color(kPrimaryColor)
              : Colors.black12),
        ),
        child: Center(child: Text(label, style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(kTextColor)))),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final int goal; final ValueChanged<int> onChanged;
  const _GoalPage({required this.goal, required this.onChanged});

  static const List<Map<String, dynamic>> _presets = [
    {'label': 'Light', 'steps': 5000, 'desc': 'Easy daily activity'},
    {'label': 'Moderate', 'steps': 8000, 'desc': 'WHO recommended'},
    {'label': 'Active', 'steps': 10000, 'desc': 'Fitness focused'},
    {'label': 'Athlete', 'steps': 15000, 'desc': 'High performance'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Daily Goal', style: GoogleFonts.outfit(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: const Color(kTextColor))),
          const SizedBox(height: 8),
          Text('How active do you want to be?', style: GoogleFonts.outfit(
              color: const Color(kSecondaryTextColor))),
          const SizedBox(height: 32),
          ..._presets.map((p) {
            final selected = goal == p['steps'] as int;
            return GestureDetector(
              onTap: () => onChanged(p['steps'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? const Color(kPrimaryColor) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected
                      ? const Color(kPrimaryColor) : Colors.black12),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['label'] as String, style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : const Color(kTextColor))),
                        Text(p['desc'] as String, style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: selected ? Colors.white70 : const Color(kSecondaryTextColor))),
                      ])),
                  Text('${((p['steps'] as int) / 1000).toStringAsFixed(0)}K steps',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(kPrimaryColor))),
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, size: 80, color: Color(kSuccessColor)),
        const SizedBox(height: 24),
        Text('You\'re all set, $name!', textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800,
                color: const Color(kTextColor))),
        const SizedBox(height: 12),
        Text('Your personalized Stepooo engine is ready.\nStart moving!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16,
                color: const Color(kSecondaryTextColor))),
      ]),
    );
  }
}
