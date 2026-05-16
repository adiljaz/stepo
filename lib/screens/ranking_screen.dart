import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.kBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VITALITY INDEX', 
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.kPrimaryColor, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Text('RANKINGS', 
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              indicatorColor: AppConfig.kPrimaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppConfig.kTextColor,
              unselectedLabelColor: AppConfig.kSecondaryTextColor,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
              tabs: const [
                Tab(text: 'DISTRICTS (KERALA)'),
                Tab(text: 'GLOBAL ENTITIES'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DistrictRankingList(),
                  _GlobalRankingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictRankingList extends StatelessWidget {
  final List<Map<String, dynamic>> districts = [
    {'name': 'Ernakulam', 'steps': '1.2M', 'growth': '+12%', 'icon': Icons.location_city},
    {'name': 'Thiruvananthapuram', 'steps': '1.1M', 'growth': '+8%', 'icon': Icons.account_balance},
    {'name': 'Kozhikode', 'steps': '980K', 'growth': '+15%', 'icon': Icons.beach_access},
    {'name': 'Thrissur', 'steps': '850K', 'growth': '+5%', 'icon': Icons.festival},
    {'name': 'Malappuram', 'steps': '820K', 'growth': '+20%', 'icon': Icons.sports_soccer},
    {'name': 'Kannur', 'steps': '790K', 'growth': '+2%', 'icon': Icons.fort},
    {'name': 'Kottayam', 'steps': '750K', 'growth': '+6%', 'icon': Icons.menu_book},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: districts.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _RankingTile(
            rank: index + 1,
            title: districts[index]['name'],
            subtitle: '${districts[index]['steps']} steps collectively',
            trailing: districts[index]['growth'],
            icon: districts[index]['icon'],
            color: index < 3 ? AppConfig.kPrimaryColor : AppConfig.kSecondaryTextColor,
          ),
        );
      },
    );
  }
}

class _GlobalRankingList extends StatelessWidget {
  final List<Map<String, dynamic>> players = [
    {'name': 'Arjun V.', 'steps': '24,531', 'img': 'A'},
    {'name': 'Meera K.', 'steps': '22,102', 'img': 'M'},
    {'name': 'Rahul R.', 'steps': '19,870', 'img': 'R'},
    {'name': 'Sruthi S.', 'steps': '18,500', 'img': 'S'},
    {'name': 'Adil J.', 'steps': '15,400', 'img': 'A'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: players.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _RankingTile(
            rank: index + 1,
            title: players[index]['name'],
            subtitle: '${players[index]['steps']} steps',
            trailing: '#${index + 1}',
            avatar: players[index]['img'],
            color: index == 0 ? AppConfig.kPrimaryColor : AppConfig.kSecondaryColor,
          ),
        );
      },
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String trailing;
  final IconData? icon;
  final String? avatar;
  final Color color;

  const _RankingTile({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.icon,
    this.avatar,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.kSurfaceColor,
        borderRadius: AppConfig.kOrganicRadius,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(rank.toString(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(width: 16),
          if (avatar != null)
             CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Text(avatar!, style: TextStyle(color: color)))
          else
             Icon(icon ?? Icons.map, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppConfig.kTextColor)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.kSecondaryTextColor)),
              ],
            ),
          ),
          Text(trailing, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
