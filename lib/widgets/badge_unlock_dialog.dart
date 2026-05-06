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
      transitionDuration: const Duration(milliseconds: 400),
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

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(kPrimaryColor).withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold glow ring
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(kWarningColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(kWarningColor).withOpacity(0.4),
                      width: 3),
                ),
                child: Center(
                  child: Text(widget.badge.icon,
                      style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Badge Unlocked!',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(kWarningColor),
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(widget.badge.title,
                  style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(kTextColor))),
              const SizedBox(height: 8),
              Text(widget.badge.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(kSecondaryTextColor))),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(kPrimaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text('Awesome!',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
