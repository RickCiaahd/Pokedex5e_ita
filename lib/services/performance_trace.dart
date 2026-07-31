import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

/// Lightweight runtime measurements exposed to DevTools and debug logs.
///
/// Release builds keep the timeline hooks available to profile tooling without
/// printing user-facing output. Debug builds emit one machine-readable line so
/// CI and Android logcat captures can preserve a repeatable baseline.
class PerformanceTrace {
  PerformanceTrace._();

  static PerformanceTraceHandle start(
    String name, {
    Map<String, Object?> arguments = const {},
  }) {
    return PerformanceTraceHandle._(name, arguments);
  }
}

class PerformanceTraceHandle {
  PerformanceTraceHandle._(this.name, this._startArguments)
    : _stopwatch = Stopwatch()..start(),
      _timelineTask = TimelineTask()..start(
        name,
        arguments: _timelineArguments(_startArguments),
      );

  final String name;
  final Map<String, Object?> _startArguments;
  final Stopwatch _stopwatch;
  final TimelineTask _timelineTask;
  bool _isFinished = false;

  Duration finish({Map<String, Object?> arguments = const {}}) {
    if (_isFinished) return _stopwatch.elapsed;
    _isFinished = true;
    _stopwatch.stop();

    final payload = <String, Object?>{
      'event': name,
      'durationMs': _stopwatch.elapsedMicroseconds / 1000,
      ..._startArguments,
      ...arguments,
    };
    _timelineTask.finish(arguments: _timelineArguments(payload));
    if (kDebugMode) {
      debugPrint('TRAINER_ATLAS_PERF ${jsonEncode(payload)}');
    }
    return _stopwatch.elapsed;
  }
}

Map<String, dynamic> _timelineArguments(Map<String, Object?> values) {
  return {
    for (final entry in values.entries)
      if (entry.value != null) entry.key: entry.value,
  };
}
