final Map<String, int> _counts = {};
bool dartchessTelemetryEnabled = true;

/// example use:
///  bool isLegal(Move move) {
///    if (move is DropMove) {
///      recordDartchessMetric('Position.isLegal:drop');
///    } else {
///      recordDartchessMetric('Position.isLegal:normal');
///    }
///  }
/// Increment the call count for a specific feature.
@pragma('vm:prefer-inline')
void recordDartchessMetric(String metric) {
  if (!dartchessTelemetryEnabled) return;
  _counts[metric] = (_counts[metric] ?? 0) + 1;
}

/// Formats and returns the telemetry results as a text block.
String generateDartchessReport() {
  final sorted = _counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final buffer = StringBuffer();
  buffer.writeln('\n========= DARTCHESS USAGE REPORT =========');
  for (final entry in sorted) {
    buffer.writeln('${entry.key.padRight(40)} : ${entry.value} calls');
  }
  buffer.writeln('==========================================\n');
  return buffer.toString();
}

/// Resets the collected tracking data.
void resetDartchessTelemetry() => _counts.clear();
