import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/social_profile.dart';

void main() {
  final now = DateTime(2026, 9, 19, 12);
  Map<String, dynamic> snapshot() => {
    'uid': 'friend',
    'name': 'Friend',
    'lastUpdatedAt': now.millisecondsSinceEpoch,
    'todaySteps': 0,
    'todayWorkouts': 0,
    'currentStreak': 0,
    'weeklySteps': 0,
    'weeklyWorkouts': 0,
  };

  test('An incomplete sharing profile never becomes fresh recorded zeros', () {
    final profile = SocialProfile.fromJson({'uid': 'friend'});
    expect(profile.hasValidSharedTimestamp, isFalse);
    expect(profile.statsDay, isNull);
    expect(profile.isCurrentDay(now), isFalse);
    expect(profile.hasKnownTodaySteps, isFalse);
    expect(profile.hasKnownWeeklySteps, isFalse);
    expect(profile.todayWorkoutsValue, isNull);
    expect(profile.weeklyWorkoutsValue, isNull);
    expect(profile.currentStreakValue, isNull);
  });

  test('Explicit zero steps remain known and legacy zero stays unknown', () {
    final legacy = snapshot();
    expect(SocialProfile.fromJson(legacy).hasKnownTodaySteps, isFalse);
    expect(
      SocialProfile.fromJson({
        ...legacy,
        'hasStepsRecord': true,
      }).hasKnownTodaySteps,
      isTrue,
    );
    expect(
      SocialProfile.fromJson({...legacy, 'todaySteps': 25}).hasKnownTodaySteps,
      isTrue,
    );
    expect(
      SocialProfile.fromJson({
        ...legacy,
        'todaySteps': 25,
        'hasStepsRecord': false,
      }).hasKnownTodaySteps,
      isFalse,
    );
    expect(
      SocialProfile.fromJson({
        ...legacy,
        'weeklyStepsRecordedDays': 2,
      }).hasKnownWeeklySteps,
      isTrue,
    );
  });

  test(
    'Malformed numbers and timestamps remain unavailable without throwing',
    () {
      final profile = SocialProfile.fromJson({
        ...snapshot(),
        'todaySteps': -1,
        'hasStepsRecord': true,
        'todayWorkouts': 1.5,
        'weeklySteps': double.nan,
        'weeklyStepsRecordedDays': 5,
        'weeklyWorkouts': '2',
        'currentStreak': double.infinity,
        'todayScore': 101,
        'weekScore': -2,
        'lastUpdatedAt': 'yesterday',
      });
      expect(profile.hasKnownTodaySteps, isFalse);
      expect(profile.hasKnownWeeklySteps, isFalse);
      expect(profile.todayWorkoutsValue, isNull);
      expect(profile.weeklyWorkoutsValue, isNull);
      expect(profile.currentStreakValue, isNull);
      expect(profile.todayScore, isNull);
      expect(profile.weekScore, isNull);
      expect(profile.statsDay, isNull);
    },
  );

  test('Explicit data date wins over a later transmission timestamp', () {
    final profile = SocialProfile.fromJson({
      ...snapshot(),
      'statsDate': '2026-09-18',
    });
    expect(profile.isCurrentDay(now), isFalse);
    expect(profile.statsDay, DateTime(2026, 9, 18));
    expect(profile.isCurrentWeek(now), isTrue);
    expect(
      SocialProfile.fromJson({
        ...snapshot(),
        'statsDate': '2026-09-20',
      }).isCurrentDay(now),
      isFalse,
    );
    expect(
      SocialProfile.fromJson({
        ...snapshot(),
        'statsDate': '2026-09-20',
      }).isCurrentWeek(now),
      isFalse,
    );
  });

  test(
    'Calendar metadata rejects rollover dates and non-Monday week starts',
    () {
      final invalid = SocialProfile.fromJson({
        ...snapshot(),
        'statsDate': '2026-08-50',
      });
      expect(invalid.statsDay, isNull);
      final badWeek = SocialProfile.fromJson({
        ...snapshot(),
        'statsDate': '2026-09-19',
        'weekStartDate': '2026-09-15',
      });
      expect(badWeek.sharedWeekStart, isNull);
      expect(badWeek.isCurrentWeek(now), isFalse);
      expect(
        SocialProfile.fromJson({
          ...snapshot(),
          'statsDate': '2025-09-19',
        }).isCurrentDay(now),
        isFalse,
      );
    },
  );

  test(
    'Legacy trailing-seven score does not become a current-week average',
    () {
      final legacy = {...snapshot(), 'weekScore': 80};
      expect(SocialProfile.fromJson(legacy).hasKnownWeekScore, isFalse);
      expect(
        SocialProfile.fromJson({
          ...legacy,
          'weekStartDate': '2026-09-14',
          'weekScoreRecordedDays': 0,
        }).hasKnownWeekScore,
        isFalse,
      );
      final dated = SocialProfile.fromJson({
        ...legacy,
        'statsDate': '2026-09-19',
        'weekStartDate': '2026-09-14',
        'weekScoreRecordedDays': 3,
      });
      expect(dated.hasKnownWeekScore, isTrue);
      expect(dated.isCurrentWeek(now), isTrue);
      expect(dated.isCurrentWeek(DateTime(2026, 9, 21)), isFalse);
    },
  );

  test(
    'Snapshot dates, coverage and explicit null scores survive serialization',
    () {
      final profile = SocialProfile.fromJson({
        ...snapshot(),
        'statsDate': '2026-09-19',
        'weekStartDate': '2026-09-14',
        'hasStepsRecord': true,
        'weeklyStepsRecordedDays': 2,
        'weekScoreRecordedDays': 2,
        'weekScore': 0,
      });
      final json = profile.toJson();
      expect(json.containsKey('todayScore'), isTrue);
      expect(json['todayScore'], isNull);
      final restored = SocialProfile.fromJson(json);
      expect(restored.hasKnownTodaySteps, isTrue);
      expect(restored.hasKnownWeeklySteps, isTrue);
      expect(restored.hasKnownWeekScore, isTrue);
      expect(restored.weekScore, 0);
      expect(restored.weeklyStepsRecordedDays, 2);
      expect(restored.statsDate, '2026-09-19');
    },
  );
}
