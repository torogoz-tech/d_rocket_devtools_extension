import 'package:d_rocket_devtools_extension/src/drocket_diagnostic_event_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deduplicates events across a reconnect and keeps newest first', () {
    final buffer = DrocketDiagnosticEventBuffer(capacity: 2);
    final older = <String, Object?>{
      'id': 'older',
      'startedAt': '2026-10-08T10:00:00Z',
    };
    final newer = <String, Object?>{
      'id': 'newer',
      'startedAt': '2026-10-08T10:01:00Z',
    };

    expect(buffer.add(older), isTrue);
    expect(buffer.add(newer), isTrue);
    expect(buffer.add(Map<String, Object?>.of(newer)), isFalse);
    expect(
        buffer.items.map((event) => event['id']), <String>['newer', 'older']);
  });

  test('trims the oldest events at the configured capacity', () {
    final buffer = DrocketDiagnosticEventBuffer(capacity: 2);
    for (int i = 0; i < 3; i++) {
      buffer.add(<String, Object?>{
        'id': '$i',
        'startedAt': '2026-10-08T10:0$i:00Z',
      });
    }

    expect(buffer.items.map((event) => event['id']), <String>['2', '1']);
  });
}
