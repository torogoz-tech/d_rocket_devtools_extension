import 'package:flutter/material.dart';

import 'drocket_diagnostic_category_badge.dart';
import 'drocket_diagnostic_details_dialog.dart';
import 'drocket_diagnostic_formatters.dart';

class DrocketDiagnosticEventTile extends StatelessWidget {
  const DrocketDiagnosticEventTile({super.key, required this.event});

  final Map<String, Object?> event;

  @override
  Widget build(BuildContext context) {
    final bool success = event['success'] != false;
    final durationLabel = formatDiagnosticDuration(event['durationMicros']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => DrocketDiagnosticDetailsDialog(event: event),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 14),
              DrocketDiagnosticCategoryBadge(
                category: '${event['category'] ?? 'unknown'}',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${event['operation'] ?? 'unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatDiagnosticTimestamp(event['startedAt']),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                durationLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
