import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/step_provider.dart';
import '../constants/step_constants.dart';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stepTrackerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('v7.0 AI ENGINE TELEMETRY', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10)),
              const Spacer(),
              _statusChip("ENGINE ALIVE", Colors.greenAccent),
            ],
          ),
          const Divider(color: Colors.white12),
          _buildRow('ML Confidence', '${(state.mlConfidence * 100).toStringAsFixed(1)}%'),
          _buildRow('Spectral Freq', '${state.fftFreq.toStringAsFixed(2)} Hz'),
          _buildRow('Current Tier', state.currentTier.name.toUpperCase(), color: _getTierColor(state.currentTier)),
          _buildRow('Pending Steps', '${state.pendingSteps}'),
          _buildRow('Rejected Today', '${state.rejectedToday}', color: state.rejectedToday > 0 ? Colors.redAccent : Colors.white70),
          _buildRow('Software Count', '${state.steps}', color: Colors.greenAccent),
          if (state.lastStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('STATUS: ${state.lastStatus}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
  );

  Color _getTierColor(dynamic tier) {
    // Note: ConfirmationTier names should match
    final name = tier.toString();
    if (name.contains('tier1')) return AppConfig.kSuccessColor;
    if (name.contains('tier2')) return AppConfig.kWarningColor;
    if (name.contains('tier3')) return AppConfig.kAccentColor;
    return AppConfig.kErrorColor;
  }

  Widget _buildRow(String label, String value, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
