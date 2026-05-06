import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';

/// Animated circular step progress indicator.
///
/// Uses a [CustomPainter] with two arcs (background track + coloured progress
/// arc). The progress arc is driven by a [TweenAnimationBuilder] so value
/// changes animate smoothly.
class StepCircle extends StatelessWidget {
  final int steps;
  final int goal;

  const StepCircle({super.key, required this.steps, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arc painter.
              CustomPaint(
                size: const Size(230, 230),
                painter: _ArcPainter(progress: animatedProgress),
              ),
              // Centre text.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    steps.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: const Color(kPrimaryColor),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'steps',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(kPrimaryColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Goal: $goal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(kPrimaryColor),
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
}

class _ArcPainter extends CustomPainter {
  final double progress;

  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;
    const startAngle = math.pi * 0.75; // Start at bottom-left (~225°)
    const sweepMax = math.pi * 1.5;   // 270° sweep

    // Background track.
    final trackPaint = Paint()
      ..color = const Color(0xFFE8E6FF)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      startAngle,
      sweepMax,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    // Progress arc with gradient.
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepMax,
      colors: const [
        Color(0xFF818CF8), // lighter indigo
        Color(0xFF4F46E5), // primary indigo
        Color(0xFF7C3AED), // violet
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      startAngle,
      sweepMax * progress,
      false,
      progressPaint,
    );

    // Glow dot at the tip of the arc.
    final tipAngle = startAngle + sweepMax * progress;
    final tipX = centre.dx + radius * math.cos(tipAngle);
    final tipY = centre.dy + radius * math.sin(tipAngle);

    final glowPaint = Paint()
      ..color = const Color(kPrimaryColor).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(tipX, tipY), 10, glowPaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tipX, tipY), 6, dotPaint);

    final dotBorderPaint = Paint()
      ..color = const Color(kPrimaryColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(tipX, tipY), 6, dotBorderPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.progress != progress;
}
