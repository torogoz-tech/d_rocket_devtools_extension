import 'dart:async';
import 'dart:convert';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drocket_diagnostic_event_tile.dart';
import 'drocket_diagnostic_metric_card.dart';
import 'drocket_diagnostics_screen.dart';

class DrocketDiagnosticsScreenState extends State<DrocketDiagnosticsScreen> {
  final List<Map<String, Object?>> events = <Map<String, Object?>>[];
  final TextEditingController searchController = TextEditingController();
  String filter = 'all';
  String searchQuery = '';
  String? error;
  bool loading = true;
  bool connected = false;
  bool diagnosticsEnabled = false;
  bool includeSensitiveData = false;
  int bufferCapacity = 500;
  StreamSubscription<dynamic>? eventSubscription;

  @override
  void initState() {
    super.initState();
    serviceManager.connectedState.addListener(_handleConnectionStateChange);
    connected = serviceManager.connectedState.value.connected;
    loadSnapshot();
    listenToDiagnosticEvents();
  }

  void _handleConnectionStateChange() {
    final next = serviceManager.connectedState.value.connected;
    if (mounted) setState(() => connected = next);
    if (next) listenToDiagnosticEvents();
  }

  Future<void> listenToDiagnosticEvents() async {
    try {
      final service =
          serviceManager.service ?? await serviceManager.onServiceAvailable;
      if (!mounted) return;
      await eventSubscription?.cancel();
      eventSubscription = service.onExtensionEvent.listen((event) {
        if (event.extensionKind != 'd_rocket.diagnostic') return;
        final dynamic data = event.extensionData?.data;
        if (data is! Map) return;
        final diagnostic = data.cast<String, Object?>();
        if (!mounted) return;
        if (_hasEvent(diagnostic)) return;
        setState(() {
          events.insert(0, diagnostic);
          if (events.length > 500) events.removeLast();
          _sortEventsByTimestamp();
        });
      });
    } catch (_) {
      // The refresh action remains available when VM Service is unavailable.
    }
  }

  bool _hasEvent(Map<String, Object?> candidate) {
    final id = candidate['id'];
    return id != null && events.any((event) => event['id'] == id);
  }

  Future<void> loadSnapshot() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.d_rocket.diagnostics.snapshot',
      );
      final dynamic rawEvents = response.json?['events'];
      final dynamic rawBuffer = response.json?['buffer'];
      final dynamic rawCapacity =
          rawBuffer is Map ? rawBuffer['capacity'] : null;
      final dynamic rawEnabled = response.json?['enabled'];
      final dynamic rawSensitive = response.json?['includeSensitiveData'];
      if (rawCapacity is num) bufferCapacity = rawCapacity.toInt();
      if (rawEnabled is bool) diagnosticsEnabled = rawEnabled;
      if (rawSensitive is bool) includeSensitiveData = rawSensitive;
      if (rawEvents is List) {
        setState(() {
          events
            ..clear()
            ..addAll(rawEvents.whereType<Map>().map(
                  (event) => event.cast<String, Object?>(),
                ));
          _sortEventsByTimestamp();
        });
      }
    } catch (value) {
      setState(() => error = value.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> clearEvents() async {
    await serviceManager.callServiceExtensionOnMainIsolate(
      'ext.d_rocket.diagnostics.clear',
    );
    setState(events.clear);
  }

  Future<void> exportEvents() async {
    await Clipboard.setData(
      ClipboardData(
          text: const JsonEncoder.withIndent('  ').convert(visibleEvents)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visible events copied to clipboard')),
    );
  }

  Future<void> importEventsFromClipboard() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text;
    if (text == null || text.trim().isEmpty) return;
    final imported = <Map<String, Object?>>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final value = jsonDecode(trimmed);
        if (value is Map) {
          imported.add(value.cast<String, Object?>());
        }
      } on FormatException {
        // Ignore non-event lines so a copied CLI log can be pasted safely.
      }
    }
    if (imported.isEmpty) return;
    setState(() {
      for (final event in imported) {
        if (!_hasEvent(event)) events.add(event);
      }
      if (events.length > bufferCapacity) {
        events.removeRange(0, events.length - bufferCapacity);
      }
      _sortEventsByTimestamp();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${imported.length} event(s) imported')),
    );
  }

  @override
  void dispose() {
    eventSubscription?.cancel();
    serviceManager.connectedState.removeListener(_handleConnectionStateChange);
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, Object?>> get visibleEvents => events.where((event) {
        final matchesCategory = filter == 'all' || event['category'] == filter;
        if (!matchesCategory) return false;
        if (searchQuery.trim().isEmpty) return true;
        final query = searchQuery.toLowerCase();
        return <String>[
          '${event['operation'] ?? ''}',
          '${event['category'] ?? ''}',
          '${event['startedAt'] ?? ''}',
          '${event['metadata'] ?? ''}',
        ].join(' ').toLowerCase().contains(query);
      }).toList(growable: false);

  void _sortEventsByTimestamp() {
    events.sort((left, right) {
      final leftTime = DateTime.tryParse('${left['startedAt']}');
      final rightTime = DateTime.tryParse('${right['startedAt']}');
      if (leftTime == null && rightTime == null) return 0;
      if (leftTime == null) return 1;
      if (rightTime == null) return -1;
      return rightTime.compareTo(leftTime);
    });
  }

  int get errorCount =>
      events.where((event) => event['success'] == false).length;

  double get averageDuration {
    final durations = _durations;
    if (durations.isEmpty) return 0;
    return durations.reduce((left, right) => left + right) / durations.length;
  }

  List<double> get _durations => events
      .map((event) => event['durationMicros'])
      .whereType<num>()
      .map((value) => value.toDouble() / 1000)
      .toList(growable: false);

  double _percentile(double percentile) {
    final durations = <double>[..._durations]..sort();
    if (durations.isEmpty) return 0;
    final index = ((durations.length - 1) * percentile).round();
    return durations[index];
  }

  double get p50Duration => _percentile(0.50);
  double get p95Duration => _percentile(0.95);

  String get cacheHitRatio {
    final cacheEvents = events.where((event) => event['category'] == 'cache');
    final total = cacheEvents.length;
    if (total == 0) return '—';
    final hits = cacheEvents
        .where((event) => (event['metadata'] as Map?)?['hit'] == true)
        .length;
    return '${(hits * 100 / total).toStringAsFixed(0)}%';
  }

  int get requestsPerMinute {
    final DateTime cutoff = DateTime.now().toUtc().subtract(
          const Duration(minutes: 1),
        );
    return events.where((event) {
      final started = DateTime.tryParse('${event['startedAt']}')?.toUtc();
      return started != null && started.isAfter(cutoff);
    }).length;
  }

  Map<String, int> get eventCountsByCategory {
    final counts = <String, int>{};
    for (final event in events) {
      final category = '${event['category'] ?? 'unknown'}';
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  List<int> get timelineBuckets {
    final now = DateTime.now().toUtc();
    final buckets = List<int>.filled(10, 0);
    for (final event in events) {
      final started = DateTime.tryParse('${event['startedAt']}')?.toUtc();
      if (started == null) continue;
      final secondsAgo = now.difference(started).inSeconds;
      if (secondsAgo < 0 || secondsAgo >= 600) continue;
      final index = 9 - (secondsAgo ~/ 60);
      buckets[index]++;
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('d_rocket diagnostics'),
        actions: <Widget>[
          Tooltip(
            message: connected ? 'Connected to VM Service' : 'Disconnected',
            child: Icon(
              Icons.circle,
              size: 11,
              color: connected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 230,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search events',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: DropdownButton<String>(
              isExpanded: true,
              value: filter,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'all', child: Text('All events')),
                DropdownMenuItem(value: 'rest', child: Text('REST')),
                DropdownMenuItem(value: 'database', child: Text('Database')),
                DropdownMenuItem(value: 'linq', child: Text('LINQ')),
                DropdownMenuItem(value: 'migration', child: Text('Migration')),
                DropdownMenuItem(value: 'sync', child: Text('Sync')),
                DropdownMenuItem(value: 'cache', child: Text('Cache')),
                DropdownMenuItem(value: 'realtime', child: Text('Realtime')),
              ],
              onChanged: (value) => setState(() => filter = value ?? 'all'),
            ),
          ),
          IconButton(
            tooltip: 'Refresh events',
            onPressed: loading ? null : loadSnapshot,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Clear events',
            onPressed: events.isEmpty ? null : clearEvents,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Copy visible events',
            onPressed: visibleEvents.isEmpty ? null : exportEvents,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: 'Import NDJSON from clipboard',
            onPressed: importEventsFromClipboard,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: <Widget>[
          Text(
            'Runtime diagnostics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Inspect activity across your data layer, synchronization, and realtime connections.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              DrocketDiagnosticMetricCard(
                label: 'Events',
                value: '${events.length}',
                icon: Icons.bolt,
              ),
              DrocketDiagnosticMetricCard(
                label: 'Average duration',
                value: '${averageDuration.toStringAsFixed(1)} ms',
                icon: Icons.speed,
              ),
              DrocketDiagnosticMetricCard(
                label: 'Errors',
                value: '$errorCount',
                icon: Icons.error_outline,
                accent: errorCount > 0 ? Colors.redAccent : Colors.green,
              ),
              DrocketDiagnosticMetricCard(
                label: 'P50 duration',
                value: '${p50Duration.toStringAsFixed(1)} ms',
                icon: Icons.speed,
              ),
              DrocketDiagnosticMetricCard(
                label: 'P95 duration',
                value: '${p95Duration.toStringAsFixed(1)} ms',
                icon: Icons.insights,
              ),
              DrocketDiagnosticMetricCard(
                label: 'Cache hit ratio',
                value: cacheHitRatio,
                icon: Icons.cached,
              ),
              DrocketDiagnosticMetricCard(
                label: 'Requests / minute',
                value: '$requestsPerMinute',
                icon: Icons.timeline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBufferSummary(context),
          const SizedBox(height: 14),
          _buildTimelineChart(context),
          const SizedBox(height: 24),
          if (loading)
            const LinearProgressIndicator()
          else if (error != null)
            _buildError(context)
          else if (visibleEvents.isEmpty)
            _buildEmptyState(context)
          else
            ...visibleEvents.map(
              (event) => DrocketDiagnosticEventTile(event: event),
            ),
        ],
      ),
    );
  }

  Widget _buildBufferSummary(BuildContext context) {
    final counts = eventCountsByCategory.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('   ');
    return Text(
      'Buffer ${events.length}/$bufferCapacity  •  '
      '${diagnosticsEnabled ? 'enabled' : 'disabled'}'
      '${includeSensitiveData ? '  •  sensitive payloads enabled' : ''}'
      '${counts.isEmpty ? '' : '  •  $counts'}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget _buildTimelineChart(BuildContext context) {
    final buckets = timelineBuckets;
    final maximum =
        buckets.fold<int>(0, (max, value) => value > max ? value : max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Events per minute (last 10 minutes)',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final value in buckets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: maximum == 0 ? 0.04 : value / maximum,
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: <Widget>[
            Icon(Icons.monitor_heart_outlined, size: 42, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No diagnostic events yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('Run an operation in your app and refresh this panel.'),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_outlined),
        title: const Text('Could not load diagnostics'),
        subtitle: Text(error!),
        trailing: TextButton(
          onPressed: loadSnapshot,
          child: const Text('Retry'),
        ),
      ),
    );
  }
}
