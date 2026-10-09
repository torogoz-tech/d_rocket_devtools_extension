import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'drocket_integration_app.dart';

void main() {
  if (kDebugMode) {
    DrocketIntegrationApp.registerDiagnostics();
  }
  runApp(const DrocketIntegrationApp());
}
