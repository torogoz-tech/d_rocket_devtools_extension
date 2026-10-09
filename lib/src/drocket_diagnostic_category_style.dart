import 'package:flutter/material.dart';

Color diagnosticCategoryColor(String category) {
  switch (category) {
    case 'rest':
      return Colors.blueAccent;
    case 'database':
      return Colors.deepPurpleAccent;
    case 'migration':
      return Colors.amber;
    case 'sync':
      return Colors.tealAccent;
    case 'cache':
      return Colors.orangeAccent;
    case 'realtime':
      return Colors.indigoAccent;
    default:
      return Colors.blueGrey;
  }
}

IconData diagnosticCategoryIcon(String category) {
  switch (category) {
    case 'rest':
      return Icons.http;
    case 'database':
      return Icons.storage_outlined;
    case 'migration':
      return Icons.swap_horiz;
    case 'sync':
      return Icons.sync;
    case 'cache':
      return Icons.cached;
    case 'realtime':
      return Icons.wifi_tethering;
    default:
      return Icons.monitor_heart_outlined;
  }
}
