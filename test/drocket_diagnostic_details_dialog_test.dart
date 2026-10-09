import 'package:d_rocket_devtools_extension/src/drocket_diagnostic_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders structured REST request and response details',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrocketDiagnosticDetailsDialog(
            event: <String, Object?>{
              'category': 'rest',
              'operation': 'POST',
              'startedAt': '2026-10-08T19:42:35.000Z',
              'finishedAt': '2026-10-08T19:42:35.008Z',
              'durationMicros': 8000,
              'success': true,
              'statusCode': 201,
              'metadata': <String, Object?>{
                'request': <String, Object?>{
                  'method': 'POST',
                  'url': 'https://api.example.test/eventos',
                  'body': '{"nombre":"demo"}',
                },
                'response': <String, Object?>{
                  'statusCode': 201,
                  'body': '{"id":"evt-1"}',
                },
              },
            },
          ),
        ),
      ),
    );

    expect(find.text('Diagnostic event'), findsOneWidget);
    expect(find.text('HTTP request'), findsOneWidget);
    expect(find.text('Request'), findsOneWidget);
    expect(find.text('Response'), findsOneWidget);
    expect(find.textContaining('"nombre": "demo"'), findsOneWidget);
    expect(find.textContaining('"id": "evt-1"'), findsOneWidget);
    expect(find.textContaining('08/10/2026'), findsNWidgets(2));
  });
}
