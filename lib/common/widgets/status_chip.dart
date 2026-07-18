import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    Color bg = const Color(0xFFEAF1FA);
    Color fg = const Color(0xFF175180);
    if (normalized.contains('approved') || normalized.contains('paid')) {
      bg = const Color(0xFFE6F7ED);
      fg = const Color(0xFF1D7A42);
    } else if (normalized.contains('rejected')) {
      bg = const Color(0xFFFFECE8);
      fg = const Color(0xFFAA3128);
    } else if (normalized.contains('submitted') ||
        normalized.contains('review')) {
      bg = const Color(0xFFFFF2E2);
      fg = const Color(0xFF8D5600);
    }

    return Chip(
      label: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
      side: BorderSide.none,
      backgroundColor: bg,
      visualDensity: VisualDensity.compact,
    );
  }
}
