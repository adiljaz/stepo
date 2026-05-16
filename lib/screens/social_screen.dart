import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/social_cubit.dart';
import '../cubits/user_settings_cubit.dart';
import '../models/user_profile.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedStatIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    // Initial fetch
    context.read<SocialCubit>().fetchSocialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SocialCubit>().fetchSocialData();
    }
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
  Widget _avatar(String initials, int c1, int c2, {double radius = 23, String? imageUrl}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl != null && imageUrl.isNotEmpty ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(c1), Color(c2)],
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _initialsAvatar(initials, radius),
              )
            : _initialsAvatar(initials, radius),
      ),
    );
  }

  Widget _initialsAvatar(String initials, double radius) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
          color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<SocialCubit, SocialState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<SocialCubit, SocialState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildStatsRow(state),
                  _buildTabBar(state),
                  _buildSearchBar(),
                  Expanded(
                    child: state.isLoading && state.friends.isEmpty && state.suggestions.isEmpty
                        ? const Center(child: CircularProgressIndicator(color: _green))
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAllTab(state),
                              _buildRequestsTab(state),
                              _buildSentTab(state),
                              _buildFriendsTab(state),
                              _buildDiscoverTab(state),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _tabController.animateTo(4),
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
        },
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return BlocBuilder<UserSettingsCubit, UserProfile>(
      builder: (context, settings) {
        final name = settings.name.isEmpty ? 'User' : settings.name;
        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
        
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
                    initials,
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
                      name,
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
      },
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

  Widget _buildStatsRow(SocialState state) {
    final stats = [
      {
        'val': state.friends.length.toString(),
        'lbl': 'Friends',
        'badge': '',
        'icon': Icons.people_outline_rounded,
      },
      {
        'val': state.incomingRequests.length.toString(),
        'lbl': 'Requests',
        'badge': state.incomingRequests.isNotEmpty ? state.incomingRequests.length.toString() : '',
        'icon': Icons.person_add_outlined,
      },
      {
        'val': state.sentRequests.length.toString(),
        'lbl': 'Sent',
        'badge': '',
        'icon': Icons.send_outlined,
      },
      {
        'val': state.suggestions.length.toString(),
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
                              horizontal: 6,
                              vertical: 1.5,
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
                                color: Colors.white,
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
  Widget _buildTabBar(SocialState state) {
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
                if (state.incomingRequests.isNotEmpty) ...[
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
                      state.incomingRequests.length.toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(text: 'Sent ${state.sentRequests.length}'),
          Tab(text: 'Friends ${state.friends.length}'),
          Tab(text: 'Suggestions ${state.suggestions.length}'),
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
                onChanged: (val) {
                  context.read<SocialCubit>().searchUsers(val);
                },
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SocialCubit>().clearSearch();
                          },
                        )
                      : null,
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
  Widget _buildAllTab(SocialState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<SocialCubit>().fetchSocialData(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildRankingPodium(state.friends),
          if (state.incomingRequests.isNotEmpty) ...[
          _sectionHeader(
            'Friend Requests',
            Icons.person_add_outlined,
            '${state.incomingRequests.length} new',
            onViewAll: () => _tabController.animateTo(1),
          ),
          ...state.incomingRequests.take(2).map((r) => _buildRequestCard(r)),
          const SizedBox(height: 20),
        ],
        if (state.sentRequests.isNotEmpty) ...[
          _sectionHeader(
            'Requests Sent',
            Icons.send_outlined,
            '${state.sentRequests.length} pending',
            onViewAll: () => _tabController.animateTo(2),
          ),
          ...state.sentRequests.take(1).map((r) => _buildSentCard(r)),
          const SizedBox(height: 20),
        ],
        if (state.friends.isNotEmpty) ...[
          _sectionHeader(
            'Your Friends',
            Icons.people_outline_rounded,
            state.friends.length.toString(),
            onViewAll: () => _tabController.animateTo(3),
          ),
          ...state.friends.take(3).map((f) => _buildFriendCard(f)),
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
                      'View all ${state.friends.length} friends',
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
      ],
    ),
  );
}

  Widget _buildRequestsTab(SocialState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<SocialCubit>().fetchSocialData(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          _sectionHeader('Incoming Requests', Icons.person_add_outlined, state.incomingRequests.length.toString()),
          if (state.incomingRequests.isEmpty) _buildEmptyState('No pending requests', Icons.person_add_disabled_outlined),
          ...state.incomingRequests.map((r) => _buildRequestCard(r)),
        ],
      ),
    );
  }

  Widget _buildSentTab(SocialState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<SocialCubit>().fetchSocialData(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          _sectionHeader('Sent Requests', Icons.send_outlined, '${state.sentRequests.length} pending'),
          if (state.sentRequests.isEmpty) _buildEmptyState('No sent requests', Icons.send_and_archive_outlined),
          ...state.sentRequests.map((r) => _buildSentCard(r)),
        ],
      ),
    );
  }

  Widget _buildFriendsTab(SocialState state) {
    return RefreshIndicator(
      onRefresh: () => context.read<SocialCubit>().fetchSocialData(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          _sectionHeader('All Friends', Icons.people_outline_rounded, state.friends.length.toString()),
          if (state.friends.isEmpty) _buildEmptyState('No friends yet', Icons.people_outline_rounded),
          ...state.friends.map((f) => _buildFriendCard(f)),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(SocialState state) {
    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    final hasSearchQuery = _searchController.text.isNotEmpty;
    final displayUsers = hasSearchQuery ? state.searchResults : state.suggestions;
    final title = hasSearchQuery ? 'Search Results' : 'Suggestions';
    final emptyMsg = hasSearchQuery ? 'No users found' : 'No suggestions';

    return RefreshIndicator(
      onRefresh: () => context.read<SocialCubit>().fetchSocialData(),
      color: _green,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _sectionHeader(title, hasSearchQuery ? Icons.search_rounded : Icons.auto_awesome_outlined, '${displayUsers.length} found'),
          if (displayUsers.isEmpty) _buildEmptyState(emptyMsg, hasSearchQuery ? Icons.person_search_rounded : Icons.auto_awesome_motion_outlined),
          ...displayUsers.map((s) => _buildSuggestionCard(s)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 64, color: _border),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.outfit(fontSize: 16, color: _textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(SocialUser r) {
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
            _avatar(r.initials, r.color1, r.color2, imageUrl: r.profileImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
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
                        '${r.steps} steps',
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
                        r.location,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
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
                  () => context.read<SocialCubit>().rejectRequest(r),
                ),
                const SizedBox(width: 8),
                _roundBtn(
                  Icons.check_rounded,
                  Colors.white,
                  _green,
                  () => context.read<SocialCubit>().acceptRequest(r),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentCard(SocialUser r) {
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
            _avatar(r.initials, r.color1, r.color2),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.steps} steps · ${r.location}',
                    style: GoogleFonts.outfit(fontSize: 12, color: _textLight),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<SocialCubit>().cancelRequest(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _textLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(SocialUser f) {
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
            _avatar(f.initials, f.color1, f.color2, imageUrl: f.profileImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        f.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                      if (f.isKing) ...[
                        const SizedBox(width: 6),
                        const Text('👑', style: TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${f.steps} steps · ${f.location}',
                    style: GoogleFonts.outfit(fontSize: 12, color: _textLight),
                  ),
                ],
              ),
            ),
            if (f.streak > 0) _streakTag(f.streak),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(SocialUser s) {
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
            _avatar(s.initials, s.color1, s.color2, imageUrl: s.profileImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.location} · ${s.mutualFriends} mutual',
                    style: GoogleFonts.outfit(fontSize: 12, color: _greenDark),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<SocialCubit>().sendRequest(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connect',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildRankingPodium(List<SocialUser> friends) {
    // Sort friends by steps descending
    final sortedFriends = List<SocialUser>.from(friends)
      ..sort((a, b) {
        int stepsA = int.tryParse(a.steps.replaceAll(',', '')) ?? 0;
        int stepsB = int.tryParse(b.steps.replaceAll(',', '')) ?? 0;
        return stepsB.compareTo(stepsA);
      });

    // Get top 3 or placeholders
    SocialUser? first = sortedFriends.length > 0 ? sortedFriends[0] : null;
    SocialUser? second = sortedFriends.length > 1 ? sortedFriends[1] : null;
    SocialUser? third = sortedFriends.length > 2 ? sortedFriends[2] : null;

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
              if (second != null)
                _podiumItem(second.name.split(' ')[0], second.steps, 2, second.initials, second.color1, second.color2, 80)
              else
                _podiumPlaceholder(2, 80),
              
              // 1st Place
              if (first != null)
                _podiumItem(first.name.split(' ')[0], first.steps, 1, first.initials, first.color1, first.color2, 110)
              else
                _podiumPlaceholder(1, 110),
                
              // 3rd Place
              if (third != null)
                _podiumItem(third.name.split(' ')[0], third.steps, 3, third.initials, third.color1, third.color2, 60)
              else
                _podiumPlaceholder(3, 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumPlaceholder(int rank, double height) {
    return Column(
      children: [
        Container(
          width: rank == 1 ? 60 : 50,
          height: rank == 1 ? 60 : 50,
          decoration: BoxDecoration(
            color: _bg,
            shape: BoxShape.circle,
            border: Border.all(color: _border, width: 1),
          ),
          child: Center(child: Icon(Icons.person_outline, color: _border, size: rank == 1 ? 30 : 25)),
        ),
        const SizedBox(height: 8),
        Text("...", style: GoogleFonts.outfit(fontSize: 12, color: _border)),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: _bg.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
      ],
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
              child: _avatar(initials, c1, c2, radius: avatarSize), // Podium might not need imageUrl as it's small or we can add it later
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
