import 'dart:convert';

import 'package:flutter/material.dart';

import 'drocket_diagnostic_category_badge.dart';

class DrocketDiagnosticEventTile extends StatelessWidget {
  const DrocketDiagnosticEventTile({super.key, required this.event});

  final Map<String, Object?> event;

  @override
  Widget build(BuildContext context) {
    final bool success = event['success'] != false;
    final duration = event['durationMicros'];
    final durationLabel = duration is num
        ? '${(duration.toDouble() / 1000).toStringAsFixed(1)} ms'
        : '—';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? Colors.green : Colors.redAccent,
        ),
        title: Row(
          children: <Widget>[
            DrocketDiagnosticCategoryBadge(
              category: '${event['category'] ?? 'unknown'}',
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${event['operation'] ?? 'unknown'}')),
          ],
        ),
        subtitle: Text('${event['startedAt'] ?? 'Unknown time'} · $durationLabel'),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(event),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
