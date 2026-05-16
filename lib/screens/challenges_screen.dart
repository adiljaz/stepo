import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Challenges",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryGreen,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: "Explore"),
              Tab(text: "My Challenges"),
              Tab(text: "Invites"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ExploreChallenges(),
            _MyChallenges(),
            Center(child: Text("No Invites yet")),
          ],
        ),
      ),
    );
  }
}

class _ExploreChallenges extends StatelessWidget {
  const _ExploreChallenges();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "Ongoing", action: "View all"),
          const SizedBox(height: 16),
          const _OngoingDuelCard(
            title: "10K Steps Battle",
            endsIn: "10:23:45",
            p1Name: "You",
            p1Steps: 8749,
            p2Name: "Rohan Das",
            p2Steps: 8649,
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: "Popular Challenges"),
          const SizedBox(height: 16),
          const _PopularChallengeCard(
            title: "May Marathon",
            subtitle: "30 days challenge",
            participants: 256,
            icon: Icons.directions_run_rounded,
            color: Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 16),
          const _PopularChallengeCard(
            title: "Weekend Warrior",
            subtitle: "Group Challenge",
            participants: 45,
            icon: Icons.bolt_rounded,
            color: Color(0xFFFFF3E0),
          ),
        ],
      ),
    );
  }
}

class _MyChallenges extends StatelessWidget {
  const _MyChallenges();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("You haven't joined any challenges yet"));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        if (action != null)
          Text(action!, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
      ],
    );
  }
}

class _OngoingDuelCard extends StatelessWidget {
  final String title, endsIn, p1Name, p2Name;
  final int p1Steps, p2Steps;

  const _OngoingDuelCard({
    required this.title,
    required this.endsIn,
    required this.p1Name,
    required this.p1Steps,
    required this.p2Name,
    required this.p2Steps,
  });

  @override
  Widget build(BuildContext context) {
    final diff = (p1Steps - p2Steps).abs();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Text("Ends in $endsIn", style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _UserDuelAvatar(name: p1Name, steps: p1Steps, isLeading: p1Steps >= p2Steps),
              Text("VS", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFFEEEEEE))),
              _UserDuelAvatar(name: p2Name, steps: p2Steps, isLeading: p2Steps > p1Steps),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
            child: Text(
              "You are leading by $diff steps 🏆",
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDuelAvatar extends StatelessWidget {
  final String name;
  final int steps;
  final bool isLeading;
  const _UserDuelAvatar({required this.name, required this.steps, required this.isLeading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isLeading ? AppTheme.primaryGreen : Colors.transparent, width: 2),
            image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/100'), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(steps.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
      ],
    );
  }
}

class _PopularChallengeCard extends StatelessWidget {
  final String title, subtitle;
  final int participants;
  final IconData icon;
  final Color color;

  const _PopularChallengeCard({
    required this.title,
    required this.subtitle,
    required this.participants,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppTheme.textDark, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 4),
                Text("$participants Participants", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgWhite,
              foregroundColor: AppTheme.textDark,
              elevation: 0,
              side: const BorderSide(color: Color(0xFFF0F0F0)),
              minimumSize: const Size(60, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Join", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
