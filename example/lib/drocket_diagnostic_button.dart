import 'package:flutter/material.dart';

class DrocketDiagnosticButton extends StatelessWidget {
  const DrocketDiagnosticButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
