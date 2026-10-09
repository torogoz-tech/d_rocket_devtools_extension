import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'drocket_diagnostic_event_tile.dart';
import 'drocket_diagnostic_metric_card.dart';
import 'drocket_diagnostics_screen.dart';

class DrocketDiagnosticsScreenState extends State<DrocketDiagnosticsScreen> {
  final List<Map<String, Object?>> events = <Map<String, Object?>>[];
  String filter = 'all';
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSnapshot();
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
      if (rawEvents is List) {
        setState(() {
          events
            ..clear()
            ..addAll(rawEvents.whereType<Map>().map(
                  (event) => event.cast<String, Object?>(),
                ));
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

  List<Map<String, Object?>> get visibleEvents => events
      .where((event) => filter == 'all' || event['category'] == filter)
      .toList(growable: false);

  int get errorCount => events.where((event) => event['success'] == false).length;

  double get averageDuration {
    final durations = events
        .map((event) => event['durationMicros'])
        .whereType<num>()
        .map((value) => value.toDouble() / 1000)
        .toList(growable: false);
    if (durations.isEmpty) return 0;
    return durations.reduce((left, right) => left + right) / durations.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('d_rocket diagnostics'),
        actions: <Widget>[
          SizedBox(
            width: 150,
            child: DropdownButton<String>(
              isExpanded: true,
              value: filter,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'all', child: Text('All events')),
                DropdownMenuItem(value: 'rest', child: Text('REST')),
                DropdownMenuItem(value: 'database', child: Text('Database')),
                DropdownMenuItem(value: 'migration', child: Text('Migration')),
                DropdownMenuItem(value: 'sync', child: Text('Sync')),
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
            ],
          ),
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
