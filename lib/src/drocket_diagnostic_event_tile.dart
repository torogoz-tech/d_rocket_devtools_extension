import 'package:flutter/material.dart';

import 'drocket_diagnostic_category_badge.dart';
import 'drocket_diagnostic_category_style.dart';
import 'drocket_diagnostic_details_dialog.dart';
import 'drocket_diagnostic_formatters.dart';

class DrocketDiagnosticEventTile extends StatelessWidget {
  const DrocketDiagnosticEventTile({super.key, required this.event});

  final Map<String, Object?> event;

  @override
  Widget build(BuildContext context) {
    final bool success = event['success'] != false;
    final String category = '${event['category'] ?? 'unknown'}';
    final Color categoryColor = diagnosticCategoryColor(category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => DrocketDiagnosticDetailsDialog(event: event),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: categoryColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 28,
                child: Icon(
                  success ? diagnosticCategoryIcon(category) : Icons.error,
                  color: success ? categoryColor : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 110,
                child: DrocketDiagnosticCategoryBadge(category: category),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '${event['operation'] ?? 'unknown'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 180,
                child: Text(
                  formatDiagnosticTimestamp(event['startedAt']),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              SizedBox(
                width: 78,
                child: Text(
                  formatDiagnosticDuration(event['durationMicros']),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 20,
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
