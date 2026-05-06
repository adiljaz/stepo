enum GaitLabel { walking, running, shuffling, stairs, still, vehicle, calibrating, stationary_step, fraudulent }

abstract class GaitClassifier {
  Future<void> initialise();
  GaitLabel classify(List<double> buffer);
  void dispose();
}

class FallbackGaitClassifier implements GaitClassifier {
  @override
  Future<void> initialise() async {}

  @override
  GaitLabel classify(List<double> buffer) {
    if (buffer.isEmpty) return GaitLabel.still;
    
    // Simple heuristic-based fallback
    final mean = buffer.reduce((a, b) => a + b) / buffer.length;
    final variance = buffer.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / buffer.length;
    
    if (variance < 0.001) return GaitLabel.still;
    if (variance > 1.5) return GaitLabel.running;
    if (variance < 0.1) return GaitLabel.shuffling;
    
    return GaitLabel.walking;
  }

  @override
  void dispose() {}
}

// Note: TFLiteGaitClassifier would go here, requiring tflite_flutter
// We'll use FallbackGaitClassifier as the default for now to ensure stability.
