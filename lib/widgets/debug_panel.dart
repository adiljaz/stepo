import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/step_tracker_cubit.dart';
import '../constants/step_constants.dart';
import '../services/v7/confirmation_engine.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepTrackerCubit, StepTrackerState>(
      builder: (context, state) {
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
              _buildRow('Total Steps', '${state.steps}', color: Colors.greenAccent),
              if (state.lastStatus != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('STATUS: ${state.lastStatus}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
  );

  Color _getTierColor(ConfirmationTier tier) {
    switch (tier) {
      case ConfirmationTier.tier1Instant: return AppConfig.kSuccessColor;
      case ConfirmationTier.tier2Fast: return AppConfig.kWarningColor;
      case ConfirmationTier.tier3Deep: return AppConfig.kAccentColor;
      case ConfirmationTier.tier4Reject: return AppConfig.kErrorColor;
    }
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
