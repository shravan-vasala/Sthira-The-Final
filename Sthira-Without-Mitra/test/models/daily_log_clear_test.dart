import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';

void main() {
  final original = DailyLog(
    date: '2026-09-19',
    weight: 70.2,
    steps: 1000,
    stepsSource: 'manual',
    sleepHours: 478 / 60,
    sleepSource: 'healthConnect',
    bodyFat: 18.5,
    workoutStatus: 'partial',
    workoutDayId: 'strength',
    waterMl: 2500,
    screenTimeMinutes: 80,
    updatedAt: DateTime(2026, 9, 19, 12),
    dayFeeling: 'good',
    dayNote: 'A calm morning.',
    checkInUpdatedAt: DateTime(2026, 9, 19, 9),
  );
  final cases = <String, (DailyLog Function(DailyLog), List<String>)>{
    'weight': ((log) => log.clearWeight(), ['weight']),
    'steps': ((log) => log.clearSteps(), ['steps', 'stepsSource']),
    'sleep': ((log) => log.clearSleep(), ['sleepHours', 'sleepSource']),
    'body fat': ((log) => log.clearBodyFat(), ['bodyFat']),
    'water': ((log) => log.clearWater(), ['waterMl']),
  };
  for (final entry in cases.entries) {
    test(
      'clearing ${entry.key} preserves reflection and every unrelated reading',
      () {
        final expected = original.toJson();
        for (final field in entry.value.$2) {
          expected.remove(field);
        }
        expect(entry.value.$1(original).toJson(), expected);
      },
    );
  }
}
