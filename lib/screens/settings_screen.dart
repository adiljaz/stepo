import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/step_constants.dart';
import '../providers/user_settings_provider.dart';
import '../models/user_profile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Settings', style: GoogleFonts.outfit(color: AppConfig.kTextColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppConfig.kTextColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('AI TRACKING SENSITIVITY', style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kPrimaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildSensitivitySegmentedButton(context, ref, profile.aiSensitivity),
          const SizedBox(height: 12),
          Text(
            _getSensitivityDescription(profile.aiSensitivity),
            style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontSize: 13),
          ),
          const SizedBox(height: 40),
          Text('SYSTEM PERMISSIONS', style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kPrimaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppConfig.kSurfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.battery_charging_full_rounded, color: AppConfig.kAccentColor),
            title: Text('Battery Optimization', style: GoogleFonts.outfit(color: AppConfig.kTextColor, fontWeight: FontWeight.w600)),
            subtitle: Text('Prevent Android from stopping the step tracker in the background.', style: GoogleFonts.outfit(color: AppConfig.kSecondaryTextColor, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppConfig.kSecondaryTextColor, size: 16),
            onTap: () async {
              await Permission.ignoreBatteryOptimizations.request();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivitySegmentedButton(BuildContext context, WidgetRef ref, AISensitivity current) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SegmentedButton<AISensitivity>(
        segments: const [
          ButtonSegment(value: AISensitivity.forgiving, label: Text('Forgiving')),
          ButtonSegment(value: AISensitivity.normal, label: Text('Normal')),
          ButtonSegment(value: AISensitivity.strict, label: Text('Strict')),
        ],
        selected: {current},
        onSelectionChanged: (Set<AISensitivity> selection) {
          final p = ref.read(userSettingsProvider);
          ref.read(userSettingsProvider.notifier).save(p.copyWith(aiSensitivity: selection.first));
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) return AppConfig.kPrimaryColor;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) return AppConfig.kBackgroundColor;
            return AppConfig.kTextColor;
          }),
        ),
      ),
    );
  }

  String _getSensitivityDescription(AISensitivity s) {
    switch (s) {
      case AISensitivity.forgiving:
        return "Best for softer steps, shuffles, or limps. Reduces false-positive rejection.";
      case AISensitivity.normal:
        return "Standard tracking mode. Balances accuracy and anti-cheat protection.";
      case AISensitivity.strict:
        return "Maximum anti-cheat. Highly rejects non-walking movements. Best for running.";
    }
  }
}
