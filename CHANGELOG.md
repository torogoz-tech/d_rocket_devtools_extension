# Changelog

## [0.2.0] — Unreleased

* Added live VM Service event subscription with automatic reconnect and
  duplicate suppression.
* Added timestamp sorting, category filters, search, p50/p95 latency,
  cache hit ratio, requests-per-minute and buffer status.
* Added structured REST, SQLite, migration, sync, cache and realtime modals.
* Added JSON formatting, copy-to-clipboard and NDJSON import/export support.

### Compatibility

* The extension is versioned independently from the d_rocket runtime and is
  intended to be released alongside d_rocket 2.1.0.
* External DevTools/Chrome validation remains environment-dependent; the
  Flutter widget and buffer tests run locally.
