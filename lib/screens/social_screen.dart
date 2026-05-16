import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedStatIndex = 0;

  // ── Data ──────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _friendRequests = [
    {
      'name': 'Ananya Pillai',
      'steps': '13,245',
      'location': 'Kozhikode',
      'mutual': 3,
      'initials': 'AP',
      'color1': 0xFF9FE1CB,
      'color2': 0xFF1D9E75,
    },
    {
      'name': 'Vishnu Prasad',
      'steps': '9,876',
      'location': 'Kochi',
      'mutual': 2,
      'initials': 'VP',
      'color1': 0xFF85B7EB,
      'color2': 0xFF378ADD,
    },
    {
      'name': 'Meera Raj',
      'steps': '8,123',
      'location': 'Calicut',
      'mutual': 4,
      'initials': 'MR',
      'color1': 0xFFF0997B,
      'color2': 0xFFD85A30,
    },
  ];

  final List<Map<String, dynamic>> _sentRequests = [
    {
      'name': 'Rahul Nair',
      'steps': '10,230',
      'location': 'Trivandrum',
      'daysAgo': 2,
      'initials': 'RN',
      'color1': 0xFFB5D4F4,
      'color2': 0xFF378ADD,
    },
    {
      'name': 'Sreeshanth P',
      'steps': '7,654',
      'location': 'Thrissur',
      'daysAgo': 5,
      'initials': 'SP',
      'color1': 0xFFAFA9EC,
      'color2': 0xFF7F77DD,
    },
    {
      'name': 'Aswin K',
      'steps': '6,890',
      'location': 'Palakkad',
      'daysAgo': 7,
      'initials': 'AK',
      'color1': 0xFFFAC775,
      'color2': 0xFFBA7517,
    },
  ];

  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Rohan Das',
      'steps': '10,230',
      'location': 'Kozhikode',
      'streak': 45,
      'isKing': true,
      'initials': 'RD',
      'color1': 0xFFC0DD97,
      'color2': 0xFF639922,
    },
    {
      'name': 'Amal C',
      'steps': '11,245',
      'location': 'Malappuram',
      'streak': 62,
      'isKing': false,
      'initials': 'AC',
      'color1': 0xFF97C459,
      'color2': 0xFF3B6D11,
    },
    {
      'name': 'Jithin Raj',
      'steps': '8,123',
      'location': 'Calicut',
      'streak': 28,
      'isKing': false,
      'initials': 'JR',
      'color1': 0xFFED93B1,
      'color2': 0xFFD4537E,
    },
    {
      'name': 'Ananya Pillai',
      'steps': '13,245',
      'location': 'Kozhikode',
      'streak': 19,
      'isKing': false,
      'initials': 'AP',
      'color1': 0xFF9FE1CB,
      'color2': 0xFF1D9E75,
    },
    {
      'name': 'Vishnu Prasad',
      'steps': '9,876',
      'location': 'Kochi',
      'streak': 11,
      'isKing': false,
      'initials': 'VP',
      'color1': 0xFF85B7EB,
      'color2': 0xFF378ADD,
    },
  ];

  final List<Map<String, dynamic>> _suggestions = [
    {
      'name': 'Nidhin K',
      'subtitle': '2.3 km away · 5 mutual friends',
      'initials': 'NK',
      'color1': 0xFFFAC775,
      'color2': 0xFFBA7517,
    },
    {
      'name': 'Saranya M',
      'subtitle': 'Kozhikode · 3 mutual friends',
      'initials': 'SM',
      'color1': 0xFFAFA9EC,
      'color2': 0xFF534AB7,
    },
    {
      'name': 'Arjun Kumar',
      'subtitle': '1.1 km away · 7 mutual friends',
      'initials': 'AK',
      'color1': 0xFF9FE1CB,
      'color2': 0xFF0F6E56,
    },
    {
      'name': 'Devi R',
      'subtitle': 'Malappuram · 2 mutual friends',
      'initials': 'DR',
      'color1': 0xFFF0997B,
      'color2': 0xFFD85A30,
    },
  ];

  // ── Tab labels with counts ────────────────────────────────────────────────
  List<String> get _tabLabels => [
    'All',
    'Requests',
    'Sent',
    'Friends',
    'Suggestions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(
          () =>
              _selectedStatIndex =
                  _tabController.index == 4 ? 3 : _tabController.index,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Colours ───────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF4F7F4);
  static const Color _dark = Color(0xFF1A2E1A);
  static const Color _green = Color(0xFF639922);
  static const Color _greenDark = Color(0xFF3B6D11);
  static const Color _greenMint = Color(0xFFEAF3DE);
  static const Color _border = Color(0xFFE0E8E0);
  static const Color _textLight = Color(0xFF888888);
  static const Color _amber = Color(0xFFBA7517);
  static const Color _amberBg = Color(0xFFFFF8E6);
  static const Color _amberBorder = Color(0xFFFAC775);

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _avatar(String initials, int c1, int c2, {double radius = 23}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(c1), Color(c2)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.outfit(
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _streakTag(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amberBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${days}d',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amberBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 11,
            color: Color(0xFFBA7517),
          ),
          const SizedBox(width: 4),
          Text(
            'Pending',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    String countLabel, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _greenMint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              countLabel,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _greenDark,
              ),
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatsRow(),
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildRequestsTab(),
                  _buildSentTab(),
                  _buildFriendsTab(),
                  _buildDiscoverTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _green,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'Add Friend',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF3B6D11), Color(0xFF639922)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'A',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, 👋',
                  style: GoogleFonts.outfit(fontSize: 12, color: _textLight),
                ),
                Text(
                  'Arjun',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Stack(
            children: [
              _iconBtn(Icons.notifications_none_rounded, () {}),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _border, width: 0.5),
          color: Colors.white,
        ),
        child: Icon(icon, color: _dark, size: 20),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {
        'val': '128',
        'lbl': 'Friends',
        'badge': '',
        'icon': Icons.people_outline_rounded,
      },
      {
        'val': '23',
        'lbl': 'Requests',
        'badge': '3',
        'icon': Icons.person_add_outlined,
      },
      {'val': '12', 'lbl': 'Sent', 'badge': '', 'icon': Icons.send_outlined},
      {
        'val': '56',
        'lbl': 'Suggestions',
        'badge': '',
        'icon': Icons.auto_awesome_outlined,
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          final isActive = _selectedStatIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStatIndex = i);
                _tabController.animateTo(i == 3 ? 4 : i + (i == 0 ? 0 : 0));
                // Map stat index to tab index
                final tabIdx = [0, 1, 2, 4];
                _tabController.animateTo(tabIdx[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? _green : _border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 20,
                      color: isActive ? Colors.white : _green,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s['val'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : _dark,
                          ),
                        ),
                        if ((s['badge'] as String).isNotEmpty) ...[
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : _green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s['badge'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      s['lbl'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color:
                            isActive
                                ? Colors.white.withValues(alpha: 0.8)
                                : _textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _green, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
        labelColor: _green,
        unselectedLabelColor: _textLight,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          const Tab(text: 'All'),
          Tab(
            child: Row(
              children: [
                const Text('Requests'),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '3',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Tab(text: 'Sent 12'),
          const Tab(text: 'Friends 128'),
          const Tab(text: 'Suggestions 56'),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(fontSize: 14, color: _dark),
                decoration: InputDecoration(
                  hintText: 'Search friends by name...',
                  hintStyle: GoogleFonts.outfit(
                    color: _textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFAAAAAA),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _greenMint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF639922),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── ALL TAB ───────────────────────────────────────────────────────────────
  Widget _buildAllTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ── Friend Ranking Podium
        _buildRankingPodium(),

        // ── Friend Requests section
        _sectionHeader(
          'Friend Requests',
          Icons.person_add_outlined,
          '3 new',
          onViewAll: () => _tabController.animateTo(1),
        ),
        ..._friendRequests.map((r) => _buildRequestCard(r)),

        const SizedBox(height: 20),

        // ── Sent Requests section
        _sectionHeader(
          'Requests Sent',
          Icons.send_outlined,
          '12 pending',
          onViewAll: () => _tabController.animateTo(2),
        ),
        ..._sentRequests.take(2).map((r) => _buildSentCard(r)),

        const SizedBox(height: 20),

        // ── Friends section
        _sectionHeader(
          'Your Friends',
          Icons.people_outline_rounded,
          '128',
          onViewAll: () => _tabController.animateTo(3),
        ),
        ..._friends.take(3).map((f) => _buildFriendCard(f)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => _tabController.animateTo(3),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _greenMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    color: Color(0xFF3B6D11),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View all 128 friends',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _greenDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── REQUESTS TAB ──────────────────────────────────────────────────────────
  Widget _buildRequestsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        _sectionHeader('Incoming Requests', Icons.person_add_outlined, '3'),
        ..._friendRequests.map((r) => _buildRequestCard(r)),
      ],
    );
  }

  // ── SENT TAB ──────────────────────────────────────────────────────────────
  Widget _buildSentTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        _sectionHeader('Sent Requests', Icons.send_outlined, '12 pending'),
        ..._sentRequests.map((r) => _buildSentCard(r)),
      ],
    );
  }

  // ── FRIENDS TAB ───────────────────────────────────────────────────────────
  Widget _buildFriendsTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        _sectionHeader('All Friends', Icons.people_outline_rounded, '128'),
        ..._friends.map((f) => _buildFriendCard(f)),
      ],
    );
  }

  // ── DISCOVER / SUGGESTIONS TAB ────────────────────────────────────────────
  Widget _buildDiscoverTab() {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      children: [
        _sectionHeader(
          'Suggestions',
          Icons.auto_awesome_outlined,
          '56 near you',
        ),
        ..._suggestions.map((s) => _buildSuggestionCard(s)),
      ],
    );
  }

  // ── Card Builders ─────────────────────────────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDE8), width: 0.5),
        ),
        child: Row(
          children: [
            _avatar(r['initials'], r['color1'], r['color2']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${r['steps']} steps',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r['location'],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${r['mutual']} mutual friends',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _roundBtn(
                  Icons.close_rounded,
                  Colors.grey.shade400,
                  const Color(0xFFF8F8F8),
                  () {},
                ),
                const SizedBox(width: 8),
                _roundBtn(Icons.check_rounded, Colors.white, _green, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentCard(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDE8), width: 0.5),
        ),
        child: Row(
          children: [
            _avatar(r['initials'], r['color1'], r['color2']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${r['steps']} steps',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r['location'],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sent ${r['daysAgo']} days ago',
                    style: GoogleFonts.outfit(fontSize: 11, color: _textLight),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _pendingBadge(),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> f) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDE8), width: 0.5),
        ),
        child: Row(
          children: [
            _avatar(f['initials'], f['color1'], f['color2']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        f['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                      if (f['isKing'] == true) ...[
                        const SizedBox(width: 6),
                        const Text('👑', style: TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${f['steps']} steps · ${f['location']}',
                    style: GoogleFonts.outfit(fontSize: 12, color: _textLight),
                  ),
                ],
              ),
            ),
            _streakTag(f['streak'] as int),
            const SizedBox(width: 6),
            const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFFBBBBBB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _greenMint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC0DD97), width: 0.5),
        ),
        child: Row(
          children: [
            _avatar(s['initials'], s['color1'], s['color2']),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['subtitle'],
                    style: GoogleFonts.outfit(fontSize: 12, color: _greenDark),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(
    IconData icon,
    Color iconColor,
    Color bg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: bg == _green ? null : Border.all(color: _border, width: 0.5),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _buildRankingPodium() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Friend Leaderboard",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _dark,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              _podiumItem("Amal C", "11,245", 2, "AC", 0xFF97C459, 0xFF3B6D11, 80),
              // 1st Place
              _podiumItem("Ananya P", "13,245", 1, "AP", 0xFF9FE1CB, 0xFF1D9E75, 110),
              // 3rd Place
              _podiumItem("Rohan Das", "10,230", 3, "RD", 0xFFC0DD97, 0xFF639922, 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(String name, String steps, int rank, String initials, int c1, int c2, double height) {
    Color medalColor = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    double avatarSize = rank == 1 ? 30 : 25;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _avatar(initials, c1, c2, radius: avatarSize),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                rank.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _green.withValues(alpha: rank == 1 ? 0.3 : 0.1),
                _green.withValues(alpha: 0.01),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  steps,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
