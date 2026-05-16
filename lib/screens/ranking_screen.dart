import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Rankings",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "Friends"),
              Tab(text: "District"),
              Tab(text: "State"),
              Tab(text: "India"),
              Tab(text: "Global"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RankingListContent(),
            _RankingListContent(),
            _RankingListContent(),
            _RankingListContent(),
            _RankingListContent(),
          ],
        ),
      ),
    );
  }
}

class _RankingListContent extends StatelessWidget {
  const _RankingListContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Time Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: ["Daily", "Weekly", "Monthly", "All Time"].map((label) {
              final isSelected = label == "Daily";
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textLight,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Podium
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _Podium(),
        ),
        const SizedBox(height: 24),
        // List
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 5,
              itemBuilder: (context, index) {
                final rank = index + 4;
                return _RankTile(rank: rank);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PodiumUser(rank: 2, name: "Ananya", steps: 13245, avatar: "https://i.pravatar.cc/100?u=2"),
        _PodiumUser(rank: 1, name: "Arjun Raj", steps: 15230, avatar: "https://i.pravatar.cc/100?u=1", isLarge: true),
        _PodiumUser(rank: 3, name: "Nikhil", steps: 12001, avatar: "https://i.pravatar.cc/100?u=3"),
      ],
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final int rank;
  final String name;
  final int steps;
  final String avatar;
  final bool isLarge;

  const _PodiumUser({
    required this.rank,
    required this.name,
    required this.steps,
    required this.avatar,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 80.0 : 60.0;
    return Column(
      children: [
        if (isLarge)
          const Icon(Icons.workspace_premium_rounded, color: Colors.orange, size: 24),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isLarge ? AppTheme.primaryGreen : Colors.transparent, width: 3),
                image: DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover),
              ),
            ),
            Container(
              transform: Matrix4.translationValues(0, 10, 0),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.textDark, shape: BoxShape.circle),
              child: Text(rank.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(steps.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  const _RankTile({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(rank.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
          const SizedBox(width: 16),
          const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/100')),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Amal C", // Dummy
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
          Text(
            "11,245", // Dummy
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
