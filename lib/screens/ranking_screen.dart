import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/social_cubit.dart';
import '../cubits/user_settings_cubit.dart';

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
            child: BlocBuilder<SocialCubit, SocialState>(
              builder: (context, state) {
                final rankingList = state.friends;
                if (rankingList.isEmpty) {
                  return Center(child: Text("Connect with friends to see rankings!", style: GoogleFonts.outfit(color: AppTheme.textLight)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: rankingList.length,
                  itemBuilder: (context, index) {
                    final user = rankingList[index];
                    return _RankTile(rank: index + 1, user: user);
                  },
                );
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
    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        final sorted = List<SocialUser>.from(state.friends)
          ..sort((a, b) {
            int stepsA = int.tryParse(a.steps.replaceAll(',', '')) ?? 0;
            int stepsB = int.tryParse(b.steps.replaceAll(',', '')) ?? 0;
            return stepsB.compareTo(stepsA);
          });

        if (sorted.isEmpty) {
          return const SizedBox(height: 150, child: Center(child: Text("No data")));
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (sorted.length > 1)
              _PodiumUser(rank: 2, name: sorted[1].name.split(' ')[0], steps: int.tryParse(sorted[1].steps.replaceAll(',', '')) ?? 0, initials: sorted[1].initials),
            _PodiumUser(rank: 1, name: sorted[0].name.split(' ')[0], steps: int.tryParse(sorted[0].steps.replaceAll(',', '')) ?? 0, initials: sorted[0].initials, isLarge: true),
            if (sorted.length > 2)
              _PodiumUser(rank: 3, name: sorted[2].name.split(' ')[0], steps: int.tryParse(sorted[2].steps.replaceAll(',', '')) ?? 0, initials: sorted[2].initials),
          ],
        );
      },
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final int rank;
  final String name;
  final int steps;
  final String initials;
  final bool isLarge;

  const _PodiumUser({
    required this.rank,
    required this.name,
    required this.steps,
    required this.initials,
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
                color: const Color(0xFFF0F7ED),
              ),
              child: Center(child: Text(initials, style: GoogleFonts.outfit(fontSize: isLarge ? 24 : 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
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
  final SocialUser user;
  const _RankTile({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(rank.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
          const SizedBox(width: 16),
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0F7ED)),
            child: Center(child: Text(user.initials, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
          Text(
            user.steps,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
