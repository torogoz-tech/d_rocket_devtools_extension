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
    final metadata = _metadataFor(category);
    DrocketDiagnostics.instance.record(
      DiagnosticEvent(
        category: category,
        operation: operation,
        startedAt: DateTime.now(),
        duration: Duration(milliseconds: _durationFor(category)),
        success: true,
        statusCode: category == DiagnosticCategory.rest ? 201 : null,
        metadata: metadata,
      ),
    );
    setState(() => eventCount++);
  }

  int _durationFor(DiagnosticCategory category) {
    switch (category) {
      case DiagnosticCategory.rest:
        return 184;
      case DiagnosticCategory.database:
        return 6;
      case DiagnosticCategory.migration:
        return 342;
      case DiagnosticCategory.sync:
        return 96;
      case DiagnosticCategory.cache:
        return 1;
      case DiagnosticCategory.realtime:
        return 12;
      case DiagnosticCategory.linq:
        return 4;
    }
  }

  Map<String, Object?> _metadataFor(DiagnosticCategory category) {
    switch (category) {
      case DiagnosticCategory.rest:
        return <String, Object?>{
          'request': <String, Object?>{
            'method': 'POST',
            'url': 'https://api.example.dev/eventos',
            'headers': <String, String>{
              'content-type': 'application/json',
              'x-request-id': 'req_demo_8f31',
            },
            'body': '{"nombre":"Evento demo","activo":true,"monto":125.50}',
            'bodyLength': 58,
          },
          'response': <String, Object?>{
            'statusCode': 201,
            'reasonPhrase': 'Created',
            'headers': <String, String>{'content-type': 'application/json'},
            'body': '{"id":"evt_1001","created":true}',
            'bodyLength': 34,
          },
        };
      case DiagnosticCategory.database:
        return <String, Object?>{
          'sql': 'SELECT id, nombre, monto FROM eventos WHERE activo = ?',
          'rowCount': 12,
        };
      case DiagnosticCategory.migration:
        return <String, Object?>{
          'id': 'M003',
          'name': 'add_timestamp_to_eventos',
          'steps': 2,
        };
      case DiagnosticCategory.sync:
        return <String, Object?>{
          'since': '2026-10-08T19:40:00.000Z',
          'uploaded': 3,
          'downloaded': 8,
        };
      case DiagnosticCategory.cache:
        return <String, Object?>{
          'key': 'GET https://api.example.dev/eventos',
          'hit': false,
          'etag': '"evt-2026-10-08"',
        };
      case DiagnosticCategory.realtime:
        return <String, Object?>{
          'channel': 'eventos',
          'messageType': 'event.created',
          'payloadSize': 248,
        };
      case DiagnosticCategory.linq:
        return <String, Object?>{'source': 'integration-example'};
    }
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
                  label: 'REST POST',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.rest,
                    'POST /api/eventos',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'SQLite SELECT',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.database,
                    'SELECT eventos',
                  ),
                ),
                DrocketDiagnosticButton(
                  label: 'Migration M003',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.migration,
                    'apply M003',
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
                  label: 'Cache',
                  onPressed: () => recordEvent(
                    DiagnosticCategory.cache,
                    'cache miss',
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
