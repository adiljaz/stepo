// ════════════════════════════════════════════════════════════════════════════
// logger.dart — Stepooo App-Wide Logger
// ════════════════════════════════════════════════════════════════════════════
//
// Centralised, levelled logger that replaces all print() calls throughout
// the codebase. In release builds only WARN and above are emitted to
// avoid leaking sensitive data.  In debug builds all levels are shown.
//
// Usage:
//   AppLogger.d('Tag', 'Debug message');
//   AppLogger.i('Tag', 'Info message');
//   AppLogger.w('Tag', 'Warning message');
//   AppLogger.e('Tag', 'Error message', error, stackTrace);
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';

/// Log verbosity levels, ordered from most verbose to most severe.
enum LogLevel { verbose, debug, info, warning, error }

/// Static logger façade used across the entire Stepooo codebase.
class AppLogger {
  AppLogger._();

  /// Minimum level to emit. Overridable at runtime for debug toggles.
  static LogLevel minimumLevel =
      kReleaseMode ? LogLevel.warning : LogLevel.verbose;

  // ── Level shortcuts ─────────────────────────────────────────────────────

  /// Verbose — very fine-grained sensor / filter data (per-sample).
  static void v(String tag, String message) =>
      _log(LogLevel.verbose, tag, message);

  /// Debug — flow events, gate decisions, calibration steps.
  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  /// Info — lifecycle events (service start/stop, model load).
  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  /// Warning — non-fatal anomalies (fallback activation, permission denied).
  static void w(String tag, String message, [Object? error]) =>
      _log(LogLevel.warning, tag, message, error: error);

  /// Error — exceptions, crashes, data corruption.
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _log(LogLevel.error, tag, message,
          error: error, stackTrace: stackTrace);

  // ── Core emitter ────────────────────────────────────────────────────────

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;

    final prefix = _levelPrefix(level);
    final ts     = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.mmm
    final line   = '$prefix [$ts] $tag: $message';

    // In debug mode use debugPrint so it respects Flutter's buffer limits.
    // In release mode we suppress verbose/debug — warning+ goes to console
    // for crash reporting integrations (e.g. Firebase Crashlytics sidecar).
    debugPrint(line);
    if (error != null)      debugPrint('  ↳ error: $error');
    if (stackTrace != null) debugPrint('  ↳ stack: $stackTrace');
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.verbose: return '🔬 V';
      case LogLevel.debug:   return '🐛 D';
      case LogLevel.info:    return 'ℹ️  I';
      case LogLevel.warning: return '⚠️  W';
      case LogLevel.error:   return '🔴 E';
    }
  }
}
