/// Normalizes workout section titles for display across Home and Workout detail screens.
///
/// Replaces variants of common titles with a standard string:
/// - Warm Up / Warmup / Warm-up -> Warm-up
/// - Main Workout -> Workout
/// - Cooldown / Cool Down / Cool-down -> Cool-down
///
/// Falls back to 'Section ${index + 1}' if the title is empty.
String formatSectionTitle(String? rawTitle, int sectionIndex) {
  final raw = rawTitle?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Section ${sectionIndex + 1}';
  }

  final lower = raw.toLowerCase();
  if (lower == 'warm up' || lower == 'warmup' || lower == 'warm-up') {
    return 'Warm-up';
  }
  if (lower == 'main workout') {
    return 'Workout';
  }
  if (lower == 'cooldown' || lower == 'cool down' || lower == 'cool-down') {
    return 'Cool-down';
  }

  // Preserve custom names, 'Cardio', 'Rest Day', etc.
  return raw;
}
