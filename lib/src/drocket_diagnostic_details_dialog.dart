import 'package:flutter/material.dart';

import 'drocket_diagnostic_category_badge.dart';
import 'drocket_diagnostic_formatters.dart';

class DrocketDiagnosticDetailsDialog extends StatelessWidget {
  const DrocketDiagnosticDetailsDialog({super.key, required this.event});

  final Map<String, Object?> event;

  Map<String, Object?> get metadata {
    final value = event['metadata'];
    return value is Map ? value.cast<String, Object?>() : <String, Object?>{};
  }

  String get category => '${event['category'] ?? 'unknown'}';

  @override
  Widget build(BuildContext context) {
    final bool success = event['success'] != false;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Row(
        children: <Widget>[
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Diagnostic event')),
          DrocketDiagnosticCategoryBadge(category: category),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${event['operation'] ?? 'Unknown operation'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              _sectionTitle(context, 'Summary'),
              _summaryGrid(context, success),
              const SizedBox(height: 18),
              _sectionTitle(context, _categoryTitle),
              _categoryDetails(context),
              if (event['error'] != null) ...<Widget>[
                const SizedBox(height: 18),
                _sectionTitle(context, 'Error'),
                _valuePanel(context, '${event['error']}'),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String get _categoryTitle {
    switch (category) {
      case 'rest':
        return 'HTTP request';
      case 'database':
        return 'Database query';
      case 'migration':
        return 'Migration';
      case 'sync':
        return 'Synchronization';
      case 'cache':
        return 'Cache';
      case 'realtime':
        return 'Realtime connection';
      default:
        return 'Details';
    }
  }

  Widget _summaryGrid(BuildContext context, bool success) {
    final durationLabel = event['durationMicros'] is num
        ? formatDiagnosticDuration(event['durationMicros'])
        : 'Not measured';
    return Wrap(
      spacing: 28,
      runSpacing: 12,
      children: <Widget>[
        _detail(context, 'Status', success ? 'Success' : 'Failed'),
        _detail(
          context,
          'Date and time',
          formatDiagnosticTimestamp(event['startedAt']),
        ),
        _detail(
          context,
          'Finished at',
          formatDiagnosticTimestamp(event['finishedAt']),
        ),
        _detail(context, 'Duration', durationLabel),
        if (event['statusCode'] != null)
          _detail(context, 'HTTP status', '${event['statusCode']}'),
      ],
    );
  }

  Widget _categoryDetails(BuildContext context) {
    if (category == 'rest') {
      return _restDetails(context);
    }
    final keys = _keysForCategory;
    final details = keys
        .where((key) => metadata[key] != null)
        .map((key) => _detail(context, _labelFor(key), '${metadata[key]}'))
        .toList(growable: false);
    if (details.isEmpty) {
      return _valuePanel(context, 'No additional details were recorded.');
    }
    return Wrap(spacing: 28, runSpacing: 14, children: details);
  }

  Widget _restDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _payloadPanel(context, 'Request', metadata['request']),
        const SizedBox(height: 12),
        _payloadPanel(context, 'Response', metadata['response']),
      ],
    );
  }

  Widget _payloadPanel(BuildContext context, String title, Object? value) {
    final payload = value is Map
        ? value.cast<String, Object?>()
        : <String, Object?>{};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          if (payload.isEmpty)
            const Text('No data available')
          else
            ...payload.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _detail(context, _labelFor(entry.key), '${entry.value}'),
              ),
            ),
          if (payload['bodyTruncated'] == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Body truncated by diagnostics payload limit.'),
            ),
        ],
      ),
    );
  }

  List<String> get _keysForCategory {
    switch (category) {
      case 'rest':
        return <String>['url', 'method', 'headers'];
      case 'database':
        return <String>['sql', 'rowCount'];
      case 'migration':
        return <String>['id', 'name', 'steps'];
      case 'sync':
        return <String>['since', 'uploaded', 'downloaded'];
      case 'cache':
        return <String>['key', 'hit', 'etag'];
      case 'realtime':
        return <String>['channel', 'messageType', 'payloadSize'];
      default:
        return metadata.keys.toList(growable: false);
    }
  }

  String _labelFor(String key) {
    switch (key) {
      case 'url':
        return 'URL';
      case 'rowCount':
        return 'Rows';
      case 'messageType':
        return 'Message type';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) {
    return SizedBox(
      width: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          SelectableText(
            value,
            maxLines: 3,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _valuePanel(BuildContext context, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(value),
    );
  }
}
