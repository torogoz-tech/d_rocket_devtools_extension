import 'package:d_rocket/d_rocket.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:d_rocket_devtools_extension_example/drocket_integration_app.dart';

void main() {
  testWidgets('records an event for the DevTools integration', (tester) async {
    DrocketDiagnostics.instance.configure(enabled: true);
    DrocketDiagnostics.instance.clear();

    await tester.pumpWidget(const DrocketIntegrationApp());
    await tester.tap(find.text('REST'));
    await tester.pump();

    expect(find.text('Events sent: 1'), findsOneWidget);
    expect(DrocketDiagnostics.instance.snapshot, hasLength(1));
    expect(
      DrocketDiagnostics.instance.snapshot.single.category,
      DiagnosticCategory.rest,
    );
  });
}
