import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/step_constants.dart';
import '../providers/insight_provider.dart';
import '../services/insight_engine.dart';

class InsightCarousel extends ConsumerStatefulWidget {
  const InsightCarousel({super.key});
  @override
  ConsumerState<InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends ConsumerState<InsightCarousel> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(insightProvider);
    return async.when(
      data: (insights) => _buildCarousel(insights),
      loading: () => _buildSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCarousel(List<Insight> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text('AI INSIGHTS', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppConfig.kTextColor, letterSpacing: 1)),
              const Spacer(),
              ...List.generate(insights.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 4),
                width: _currentPage == i ? 16 : 6, height: 6,
                decoration: BoxDecoration(color: _currentPage == i ? AppConfig.kPrimaryColor : AppConfig.kPrimaryColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
              )),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: insights.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InsightCard(
                insight: insights[i],
                onDismiss: () {
                  insights[i].isDismissed = true;
                  ref.invalidate(insightProvider);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSkeleton() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(height: 20, width: 80, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6))),
      SizedBox(height: 140, child: Container(decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(24)))),
      const SizedBox(height: 24),
    ],
  );
}

class InsightCard extends StatefulWidget {
  final Insight insight;
  final VoidCallback? onDismiss;
  const InsightCard({super.key, required this.insight, this.onDismiss});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  LinearGradient _accentGradient() {
    switch (widget.insight.type) {
      case InsightType.streak: return const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)]);
      case InsightType.bestDay: return const LinearGradient(colors: [Color(0xFF5D5FEF), Color(0xFF8B5CF6)]);
      case InsightType.pattern: return const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF0099CC)]);
      case InsightType.pace: return const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)]);
      case InsightType.goal: return const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFFCC02)]);
      case InsightType.milestone: return const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B8A)]);
      case InsightType.timeOfDay: return const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFAD94FF)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(color: AppConfig.kSurfaceColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, decoration: BoxDecoration(gradient: _accentGradient())),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(children: [
                          Text(widget.insight.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(widget.insight.title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppConfig.kTextColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (widget.onDismiss != null)
                            GestureDetector(onTap: widget.onDismiss, child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.close_rounded, size: 16, color: Colors.white38))),
                        ]),
                        const SizedBox(height: 8),
                        Text(widget.insight.body, style: GoogleFonts.outfit(fontSize: 12.5, color: AppConfig.kSecondaryTextColor, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
