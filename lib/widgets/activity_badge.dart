import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



/// Pill badge that displays the current activity status with colour coding.
///
/// Colour rules:
///   - WALKING / RUNNING → green (active)
///   - STILL             → amber (idle)
///   - IN_VEHICLE        → red   (filtering active)
///   - UNKNOWN           → grey
class ActivityBadge extends StatelessWidget {
  final String status;

  const ActivityBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configForStatus(status);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _BadgePill(
        key: ValueKey(status),
        label: status,
        icon: config.icon,
        color: config.color,
      ),
    );
  }

  _BadgeConfig _configForStatus(String status) {
    switch (status) {
      case 'WALKING':
        return const _BadgeConfig(
          color: Color(0xFF22C55E),
          icon: Icons.directions_walk_rounded,
        );
      case 'RUNNING':
        return const _BadgeConfig(
          color: Color(0xFF16A34A),
          icon: Icons.directions_run_rounded,
        );
      case 'STILL':
      case 'STATIONARY':
        return const _BadgeConfig(
          color: Color(0xFFF59E0B),
          icon: Icons.pause_circle_outline_rounded,
        );
      case 'VEHICLE':
      case 'IN_VEHICLE':
        return const _BadgeConfig(
          color: Color(0xFFEF4444),
          icon: Icons.directions_car_rounded,
        );
      case 'CYCLING':
        return const _BadgeConfig(
          color: Color(0xFF06B6D4), // Cyan
          icon: Icons.directions_bike_rounded,
        );
      case 'STAIRS':
        return const _BadgeConfig(
          color: Color(0xFFF43F5E), // Rose
          icon: Icons.stairs_rounded,
        );
      case 'SHUFFLING':
        return const _BadgeConfig(
          color: Color(0xFF64748B), // Slate
          icon: Icons.nordic_walking_rounded,
        );
      case 'CALIBRATING':
        return const _BadgeConfig(
          color: Color(0xFF6366F1), // Indigo
          icon: Icons.autorenew_rounded,
        );
      case 'FRAUDULENT':
        return const _BadgeConfig(
          color: Color(0xFFEF4444), // Red
          icon: Icons.gpp_bad_rounded,
        );
      case 'STATIONARY_STEP':
        return const _BadgeConfig(
          color: Color(0xFF8B5CF6), // Violet
          icon: Icons.accessibility_new_rounded,
        );
      default:
        return const _BadgeConfig(
          color: Color(0xFF94A3B8),
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _BadgeConfig {
  final Color color;
  final IconData icon;
  const _BadgeConfig({required this.color, required this.icon});
}

class _BadgePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BadgePill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot.
          _PulsingDot(color: color),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small animated pulsing dot to indicate live status.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
