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
