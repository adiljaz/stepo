import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/badge_service.dart';
import '../constants/step_constants.dart';

class BadgeUnlockDialog extends StatefulWidget {
  final AppBadge badge;
  const BadgeUnlockDialog({super.key, required this.badge});

  static Future<void> show(BuildContext context, AppBadge badge) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, __) => BadgeUnlockDialog(badge: badge),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppConfig.kSurfaceColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppConfig.kWarningColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppConfig.kWarningColor.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppConfig.kWarningColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppConfig.kWarningColor.withValues(alpha: 0.4), width: 3),
                ),
                child: Center(child: Text(widget.badge.icon, style: const TextStyle(fontSize: 54))),
              ),
              const SizedBox(height: 24),
              Text('ACHIEVEMENT UNLOCKED', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.kWarningColor, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(widget.badge.title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: AppConfig.kTextColor)),
              const SizedBox(height: 12),
              Text(widget.badge.description, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 15, color: AppConfig.kSecondaryTextColor, height: 1.4)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text('Collect Badge', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
