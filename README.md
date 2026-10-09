# d_rocket DevTools extension

This package contains the Flutter web source for the `d_rocket` DevTools
extension. The published extension assets are copied into
`d_rocket/extension/devtools`.

Build and copy the extension with:

```bash
dart run devtools_extensions build_and_copy \
  --source=. \
  --dest=extension/devtools
```

## Integration example

The `example/` application validates the complete development flow: it enables
the VM Service bridge only in debug mode, generates representative d_rocket
diagnostic events, and exposes them to the DevTools extension.

Run it with:

```bash
cd example
flutter pub get
flutter run
```

While the app is running in debug mode, open Flutter DevTools and select the
`d_rocket` tab. Press the buttons in the example app and the events should
appear without polling. The panel reconnects after a VM Service interruption,
sorts by timestamp, and opens structured details for REST, SQLite/LINQ,
migration, sync, cache, and realtime events.

The download button copies the visible events as JSON. The upload button reads
NDJSON from the clipboard, so output created by
`d_rocket:migration --diagnostics-file` can be inspected in the same timeline.
Bodies, authorization headers, cookies, API keys, and SQL bind values remain
hidden or redacted unless sensitive diagnostics were explicitly enabled in the
application.
