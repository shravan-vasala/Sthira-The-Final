class TargetParser {
  /// Parses a rep display string (e.g. "10-12", "12", "8 - 10", "3 x 10") and returns the upper bound target.
  /// If the schema suggests it's a duration (sec, min) or distance (km, m, mi), it deliberately returns 0
  /// as Sthira doesn't currently support non-rep metric PRs or falsified records.
  static int parseRepTarget(String repStr) {
    final lowerStr = repStr.trim().toLowerCase();
    if (lowerStr.isEmpty) return 0;

    // Do not fabricate reps out of durations or distances.
    if (lowerStr.contains('min') ||
        lowerStr.contains('sec') ||
        lowerStr.contains('km') ||
        lowerStr.contains('mi') ||
        lowerStr.contains('m') && !lowerStr.contains('rm')) {
      return 0; // Unsupported rep mapping for this schema
    }

    // Address format: "3 x 10" or "3x10" or "3 * 10" targeting the intended trailing repetitions.
    if (lowerStr.contains('x') || lowerStr.contains('*')) {
      final parts = lowerStr.split(RegExp(r'[x\*]'));
      if (parts.length >= 2) {
        return int.tryParse(parts.last.trim()) ?? 0;
      }
    }

    if (lowerStr.contains('-')) {
      final parts = lowerStr.split('-');
      if (parts.length >= 2) {
        return int.tryParse(parts.last.trim()) ?? 0;
      }
    }

    // Match the standard single digit / digit group
    final numMatch = RegExp(r'\d+').firstMatch(lowerStr);
    if (numMatch != null) {
      return int.parse(numMatch.group(0)!);
    }

    return 0;
  }
}
