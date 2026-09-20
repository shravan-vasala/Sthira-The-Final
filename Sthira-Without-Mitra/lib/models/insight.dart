import 'package:flutter/material.dart';

enum InsightType {
  trend, // e.g., "You walked 10k steps 5 days in a row"
  correlation, // e.g., "On days you sleep 8h, you eat 200 fewer calories"
}

enum InsightSeverity { positive, neutral, warning }

class Insight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final String? supportingText;
  final InsightSeverity severity;
  final DateTime dateGenerated;
  final IconData icon;

  const Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.supportingText,
    required this.severity,
    required this.dateGenerated,
    required this.icon,
  });
}
