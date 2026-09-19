import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';

void main() {
  group('DailyLog Check-In fields', () {
    test('toJson and fromJson handle check-in fields correctly', () {
      final now = DateTime.now();
      final log = DailyLog(
        date: '2023-10-10',
        dayFeeling: 'great',
        dayNote: 'Had a wonderful day',
        checkInUpdatedAt: now,
      );

      final json = log.toJson();
      expect(json['dayFeeling'], 'great');
      expect(json['dayNote'], 'Had a wonderful day');
      expect(json['checkInUpdatedAt'], now.toIso8601String());

      final restoredLog = DailyLog.fromJson(json);
      expect(restoredLog.date, '2023-10-10');
      expect(restoredLog.dayFeeling, 'great');
      expect(restoredLog.dayNote, 'Had a wonderful day');
      expect(restoredLog.checkInUpdatedAt?.toIso8601String(), now.toIso8601String());
    });

    test('copyWith handles check-in fields', () {
      final log = DailyLog(date: '2023-10-10');
      final updatedLog = log.copyWith(
        dayFeeling: 'okay',
        dayNote: 'Not bad',
      );
      
      expect(updatedLog.dayFeeling, 'okay');
      expect(updatedLog.dayNote, 'Not bad');
      expect(updatedLog.checkInUpdatedAt, isNull);
    });

    test('clearCheckIn correctly nullifies check-in fields', () {
      final log = DailyLog(
        date: '2023-10-10',
        dayFeeling: 'great',
        dayNote: 'Good day',
        steps: 5000,
      );

      final clearedLog = log.clearCheckIn();
      expect(clearedLog.steps, 5000); // Should retain other fields
      expect(clearedLog.dayFeeling, isNull);
      expect(clearedLog.dayNote, isNull);
    });
  });
}
