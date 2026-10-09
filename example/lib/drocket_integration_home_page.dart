import 'package:d_rocket/d_rocket.dart' hide Column;
import 'package:flutter/material.dart';

import 'drocket_diagnostic_button.dart';

class DrocketIntegrationHomePage extends StatefulWidget {
  const DrocketIntegrationHomePage({super.key});

  @override
  State<DrocketIntegrationHomePage> createState() =>
      DrocketIntegrationHomePageState();
}

class DrocketIntegrationHomePageState
    extends State<DrocketIntegrationHomePage> {
  int eventCount = 0;

  void recordEvent(DiagnosticCategory category, String operation) {
    DrocketDiagnostics.instance.record(
      DiagnosticEvent(
        category: category,
        operation: operation,
        startedAt: DateTime.now(),
        duration: const Duration(milliseconds: 8),
        success: true,
        metadata: <String, Object?>{'source': 'integration-example'},
      ),
    );
    setState(() => eventCount++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('d_rocket integration')), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Events sent: $eventCount'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                DrocketDiagnosticButton(
                  label: 'REST',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.rest,
                    'integration.request',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'SQLite/LINQ',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.database,
                    'integration.query',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'Migration',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.migration,
                    'integration.migration',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'Sync',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.sync,
                    'integration.sync',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'Realtime',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.realtime,
                    'integration.realtime',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
