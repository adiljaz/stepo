import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE MISSIONS', 
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.kSecondaryColor, letterSpacing: 3)),
              const SizedBox(height: 4),
              Text('CHALLENGES', 
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
              const SizedBox(height: 30),
              
              _ChallengeSectionHeader(title: '1 VS 1 DUELS', icon: Icons.bolt_rounded),
              const SizedBox(height: 16),
              _DuelCard(name: 'Adithya R.', goal: 15000, progress: 0.6, color: AppConfig.kPrimaryColor),
              _DuelCard(name: 'Suhail P.', goal: 10000, progress: 0.4, color: AppConfig.kSecondaryColor),
              
              const SizedBox(height: 40),
              _ChallengeSectionHeader(title: 'BIO-GROUPS', icon: Icons.groups_rounded),
              const SizedBox(height: 16),
              _GroupChallengeCard(
                title: 'Kerala Walkers Club', 
                participants: 124, 
                goal: '50M Steps Total', 
                progress: 0.75,
                color: AppConfig.kSuccessColor,
              ),
              _GroupChallengeCard(
                title: 'Urban Nomads', 
                participants: 45, 
                goal: '1M Steps Week', 
                progress: 0.2,
                color: AppConfig.kAccentColor,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _ChallengeSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppConfig.kTextColor.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppConfig.kSecondaryTextColor, letterSpacing: 1.5)),
      ],
    );
  }
}

class _DuelCard extends StatelessWidget {
  final String name;
  final int goal;
  final double progress;
  final Color color;

  const _DuelCard({required this.name, required this.goal, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1-value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConfig.kSurfaceColor,
          borderRadius: AppConfig.kOrganicRadius,
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Text(name[0], style: TextStyle(color: color))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Versus $name', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
                      Text('First to $goal steps wins', style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor)),
                    ],
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: AppConfig.kSecondaryTextColor),
              ],
            ),
            const SizedBox(height: 24),
            _ChallengeProgressBar(progress: progress, color: color),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOU: ${(progress * goal).toInt()} / $goal', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                Text('${name.toUpperCase()}: ${(0.5 * goal).toInt()}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppConfig.kSecondaryTextColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChallengeCard extends StatelessWidget {
  final String title;
  final int participants;
  final String goal;
  final double progress;
  final Color color;

  const _GroupChallengeCard({required this.title, required this.participants, required this.goal, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: AppConfig.kOrganicRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
          const SizedBox(height: 4),
          Text('$participants entities participating', style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor)),
          const SizedBox(height: 20),
          _ChallengeProgressBar(progress: progress, color: color),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GOAL: $goal', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${(progress * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  const _ChallengeProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 8,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}
