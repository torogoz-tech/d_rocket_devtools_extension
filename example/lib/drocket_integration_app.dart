import 'package:d_rocket/d_rocket.dart';
import 'package:flutter/material.dart';

import 'drocket_integration_home_page.dart';

class DrocketIntegrationApp extends StatelessWidget {
  const DrocketIntegrationApp({super.key});

  static void registerDiagnostics() {
    DrocketDevToolsBridge.register();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'd_rocket DevTools integration',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const DrocketIntegrationHomePage(),
    );
  }
}
