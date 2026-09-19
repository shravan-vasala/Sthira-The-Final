import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/utils/workout_formatting.dart';

void main() {
  group('workout_formatting', () {
    test('normalizes variants of Warm-up', () {
      expect(formatSectionTitle('Warm Up', 0), 'Warm-up');
      expect(formatSectionTitle('Warmup', 0), 'Warm-up');
      expect(formatSectionTitle('Warm-up', 0), 'Warm-up');
      expect(formatSectionTitle(' WaRm uP ', 0), 'Warm-up');
    });

    test('normalizes variants of Workout', () {
      expect(formatSectionTitle('Main Workout', 1), 'Workout');
      expect(formatSectionTitle('main WORKOUT', 1), 'Workout');
    });

    test('normalizes variants of Cool-down', () {
      expect(formatSectionTitle('Cooldown', 2), 'Cool-down');
      expect(formatSectionTitle('Cool Down', 2), 'Cool-down');
      expect(formatSectionTitle('Cool-down', 2), 'Cool-down');
      expect(formatSectionTitle('  cooldown  ', 2), 'Cool-down');
    });

    test('falls back to Section N when title is empty or null', () {
      expect(formatSectionTitle('', 0), 'Section 1');
      expect(formatSectionTitle(' ', 1), 'Section 2');
      expect(formatSectionTitle(null, 2), 'Section 3');
    });

    test('preserves custom names and known special cases like Cardio and Rest', () {
      expect(formatSectionTitle('Cardio', 0), 'Cardio');
      expect(formatSectionTitle('Rest Day', 0), 'Rest Day');
      expect(formatSectionTitle('Core Finisher', 2), 'Core Finisher');
      expect(formatSectionTitle('Section 1', 0), 'Section 1');
      expect(formatSectionTitle('Section 2', 1), 'Section 2');
    });
  });
}
