import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/step_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserSettingsCubit, UserProfile>(
      builder: (context, profile) {
        return Scaffold(
          backgroundColor: AppConfig.kBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 140,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                  title: Text(
                    'SETTINGS',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.kTextColor,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('ENGINE SENSITIVITY'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppConfig.kSurfaceColor,
                        borderRadius: BorderRadius.circular(AppConfig.kCardRadius),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildSensitivityOption(context, profile, AISensitivity.forgiving, 'Relaxed'),
                          const Divider(color: Colors.white10),
                          _buildSensitivityOption(context, profile, AISensitivity.normal, 'Balanced'),
                          const Divider(color: Colors.white10),
                          _buildSensitivityOption(context, profile, AISensitivity.strict, 'Strict'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSectionHeader('HARDWARE INTEGRATION'),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppConfig.kSurfaceColor,
                        borderRadius: BorderRadius.circular(AppConfig.kCardRadius),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        onTap: () => Permission.ignoreBatteryOptimizations.request(),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConfig.kPrimaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppConfig.kPrimaryColor),
                        ),
                        title: Text('Background Execution', style: GoogleFonts.outfit(color: AppConfig.kTextColor, fontWeight: FontWeight.w700, fontSize: 16)),
                        subtitle: Text('Prevent system sleep interrupts', style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppConfig.kSecondaryTextColor),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSectionHeader('DATA PRIVACY & SAFETY'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppConfig.kSurfaceColor,
                        borderRadius: BorderRadius.circular(AppConfig.kCardRadius),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPrivacyTile(Icons.security_rounded, '100% Local Processing', 'All sensor data stays on your device. We do not use any external cloud for AI processing.'),
                          const Divider(color: Colors.white10, height: 32),
                          _buildPrivacyTile(Icons.visibility_off_rounded, 'No Data Selling', 'Your fitness and biometric data is yours. We never share or sell information to third parties.'),
                          const Divider(color: Colors.white10, height: 32),
                          _buildPrivacyTile(Icons.delete_forever_rounded, 'Anonymized Tracking', 'Location data for workouts is stored only in local history and is never linked to your identity.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kPrimaryColor, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      );

  Widget _buildSensitivityOption(BuildContext context, UserProfile profile, AISensitivity s, String label) {
    final isSelected = profile.aiSensitivity == s;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.read<UserSettingsCubit>().save(profile.copyWith(aiSensitivity: s));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.outfit(color: isSelected ? AppConfig.kPrimaryColor : AppConfig.kTextColor, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: AppConfig.kPrimaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTile(IconData icon, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppConfig.kPrimaryColor, size: 20),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.outfit(color: AppConfig.kTextColor, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text(desc, style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
      ],
    );
  }
}

