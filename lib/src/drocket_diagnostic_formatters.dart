import 'dart:convert';

String formatDiagnosticTimestamp(Object? value) {
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) return 'Unknown time';
  final local = parsed.toLocal();
  final date = '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
  final time = '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}.'
      '${local.millisecond.toString().padLeft(3, '0')}';
  return '$date $time';
}

String formatDiagnosticDuration(Object? value) {
  if (value is! num) return '—';
  return '${(value.toDouble() / 1000).toStringAsFixed(1)} ms';
}

String formatDiagnosticValue(Object? value) {
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map || decoded is List) {
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
    } on FormatException {
      // Non-JSON bodies remain plain text.
    }
    return value;
  }
  if (value is Map || value is List) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } on Object {
      return '$value';
    }
  }
  return '$value';
}
