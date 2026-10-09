import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'drocket_diagnostics_screen.dart';

class DrocketDevToolsApp extends StatelessWidget {
  const DrocketDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: DrocketDiagnosticsScreen());
  }
}
