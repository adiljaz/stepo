import 'dart:math' as math;

/// STAGE 5 — AI & ML VALIDATION (FFT Anti-Cheat).
/// 
/// Implements Cooley-Tukey FFT for spectral analysis of gait signatures.
class FFTAntiCheat {
  /// Analyzes a 256-sample window for frequency dominance.
  FFTResult analyze(List<double> samples, double samplingHz) {
    if (samples.length < 256) return FFTResult(dominantFreq: 0, entropy: 0);

    // 1. Apply Hann Window
    final windowed = List<double>.generate(256, (i) {
      double w = 0.5 * (1 - math.cos(2 * math.pi * i / 255));
      return samples[i] * w;
    });

    // 2. Compute FFT
    final complexes = windowed.map((s) => _Complex(s, 0)).toList();
    final fft = _fft(complexes);

    // 3. Compute Power Spectrum
    final power = fft.take(128).map((c) => c.magnitude).toList();
    
    // 4. Find Dominant Frequency
    int maxIdx = 0;
    double maxVal = -1.0;
    double totalPower = 0.0;
    
    for (int i = 1; i < power.length; i++) { // Skip DC (i=0)
      totalPower += power[i];
      if (power[i] > maxVal) {
        maxVal = power[i];
        maxIdx = i;
      }
    }

    final domFreq = maxIdx * (samplingHz / 256);

    // 5. Compute Spectral Entropy
    double entropy = 0.0;
    if (totalPower > 0) {
      for (int i = 1; i < power.length; i++) {
        double p = power[i] / totalPower;
        if (p > 0) {
          entropy -= p * (math.log(p) / math.log(2));
        }
      }
      entropy /= (math.log(power.length - 1) / math.log(2)); // Normalize
    }

    return FFTResult(dominantFreq: domFreq, entropy: entropy);
  }

  List<_Complex> _fft(List<_Complex> x) {
    int n = x.length;
    if (n <= 1) return x;
    
    var even = List<_Complex>.generate(n ~/ 2, (i) => x[i * 2]);
    var odd = List<_Complex>.generate(n ~/ 2, (i) => x[i * 2 + 1]);
    
    even = _fft(even);
    odd = _fft(odd);
    
    var results = List<_Complex>.filled(n, _Complex(0, 0));
    for (int k = 0; k < n ~/ 2; k++) {
      double t = -2 * math.pi * k / n;
      var exp = _Complex(math.cos(t), math.sin(t));
      var p = even[k];
      var q = exp * odd[k];
      results[k] = p + q;
      results[k + n ~/ 2] = p - q;
    }
    return results;
  }
}

class FFTResult {
  final double dominantFreq;
  final double entropy;

  FFTResult({required this.dominantFreq, required this.entropy});

  bool get isMechanical => dominantFreq > 8.0;
  bool get isHumanWalk => dominantFreq >= 0.8 && dominantFreq <= 2.5;
  bool get isHumanRun => dominantFreq > 2.5 && dominantFreq <= 4.0;
  bool get isAmbiguous => dominantFreq > 4.0 && dominantFreq <= 8.0;
  bool get isStatic => dominantFreq < 0.5;
}

class _Complex {
  final double re;
  final double im;
  _Complex(this.re, this.im);

  _Complex operator +( _Complex o) => _Complex(re + o.re, im + o.im);
  _Complex operator -( _Complex o) => _Complex(re - o.re, im - o.im);
  _Complex operator *( _Complex o) => _Complex(re * o.re - im * o.im, re * o.im + im * o.re);
  double get magnitude => math.sqrt(re * re + im * im);
}
