import 'package:flutter/material.dart';
import '../../core/network/network_checker.dart';

class ConnectionBanner extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onRetry;

  const ConnectionBanner({
    super.key,
    required this.isVisible,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠ Server Connection Lost. Please check your network.',
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
