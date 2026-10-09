import 'package:flutter/material.dart';

class DrocketDiagnosticCategoryBadge extends StatelessWidget {
  const DrocketDiagnosticCategoryBadge({
    super.key,
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          category.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Color _colorFor(String value) {
    switch (value) {
      case 'rest':
        return Colors.blueAccent;
      case 'database':
        return Colors.deepPurpleAccent;
      case 'migration':
        return Colors.amber;
      case 'sync':
        return Colors.tealAccent;
      case 'realtime':
        return Colors.indigoAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
