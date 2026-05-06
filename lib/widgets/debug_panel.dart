import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/step_provider.dart';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stepStateProvider);
    final service = ref.watch(stepTrackingProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENGINE DEBUG PANEL',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Divider(color: Colors.white12),
          StreamBuilder<String>(
            stream: service.debugStream,
            builder: (context, snapshot) {
              final data = snapshot.data ?? 'Waiting for signal...';
              return Text(
                'Live: $data',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildDebugRow('Fraud Score', state.lastFraudScore.toStringAsFixed(3)),
          _buildDebugRow('Warmup', '${state.calibrationProgress}/30'),
          _buildDebugRow('Isolate', 'ALIVE', color: Colors.greenAccent),
          _buildDebugRow('Permissions', state.isBackgroundActive ? 'GRANTED' : 'DENIED', 
            color: state.isBackgroundActive ? Colors.greenAccent : Colors.redAccent),
          _buildDebugRow('Hardware Steps', '${state.hardwareSteps}'),
          _buildDebugRow('Software Steps', '${state.softwareSteps}'),
          if (state.lastRejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Last Reject: ${state.lastRejectionReason}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, {Color color = Colors.white70}) {
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
