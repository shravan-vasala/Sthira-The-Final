import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/screens/social/social_feed_screen.dart';

final _now = DateTime(2026, 9, 16, 12);

Map<String, dynamic> _sharedJson() => {
  'uid': 'friend-a',
  'name': 'Friend',
  'lastUpdatedAt': _now.millisecondsSinceEpoch,
  'statsDate': '2026-09-16',
  'weekStartDate': '2026-09-14',
  'todaySteps': 600,
  'weeklySteps': 1200,
  'hasStepsRecord': true,
  'weeklyStepsRecordedDays': 2,
  'todayScore': 75,
  'weekScore': 50,
  'weekScoreRecordedDays': 2,
};

SocialProfile _profile([Map<String, dynamic> fields = const {}]) =>
    SocialProfile.fromJson({..._sharedJson(), ...fields});

int? _value(
  SocialProfile profile,
  LeaderboardPeriod period,
  LeaderboardMetric metric,
) => leaderboardValue(profile, period, metric, _now);

void main() {
  test('each leaderboard period reads its own shared metric', () {
    final profile = _profile();
    expect(
      _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
      600,
    );
    expect(
      _value(profile, LeaderboardPeriod.today, LeaderboardMetric.score),
      75,
    );
    expect(
      _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
      1200,
    );
    expect(
      _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
      50,
    );
  });

  test('explicit recorded zero remains a valid rank for steps and scores', () {
    final profile = _profile({
      'todaySteps': 0,
      'weeklySteps': 0,
      'todayScore': 0,
      'weekScore': 0,
      'weeklyStepsRecordedDays': 1,
      'weekScoreRecordedDays': 1,
    });
    for (final period in LeaderboardPeriod.values) {
      for (final metric in LeaderboardMetric.values) {
        expect(_value(profile, period, metric), 0);
      }
    }
  });

  test(
    'unrecorded steps and missing scores stay unranked rather than zero',
    () {
      final profile = _profile({
        'todaySteps': 0,
        'weeklySteps': 0,
        'hasStepsRecord': false,
        'weeklyStepsRecordedDays': 0,
        'todayScore': null,
        'weekScore': null,
        'weekScoreRecordedDays': 0,
      });
      for (final period in LeaderboardPeriod.values) {
        for (final metric in LeaderboardMetric.values) {
          expect(_value(profile, period, metric), isNull);
        }
      }
    },
  );

  test(
    'yesterday is unavailable for Today while its current-week totals remain useful',
    () {
      final profile = _profile({'statsDate': '2026-09-15'});
      expect(
        _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
        isNull,
      );
      expect(
        _value(profile, LeaderboardPeriod.today, LeaderboardMetric.score),
        isNull,
      );
      expect(
        _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
        1200,
      );
      expect(
        _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
        50,
      );
    },
  );

  for (final dates in [
    {'statsDate': '2026-09-13', 'weekStartDate': '2026-09-07'},
    {'statsDate': '2026-09-17', 'weekStartDate': '2026-09-14'},
    {'statsDate': '2026-09-21', 'weekStartDate': '2026-09-21'},
    {'statsDate': '2026-09-31', 'weekStartDate': '2026-09-14'},
  ]) {
    test(
      'stale, future or invalid shared day ${dates['statsDate']} cannot rank',
      () {
        final profile = _profile(dates);
        for (final period in LeaderboardPeriod.values) {
          for (final metric in LeaderboardMetric.values) {
            expect(_value(profile, period, metric), isNull);
          }
        }
      },
    );
  }

  test(
    'invalid or mismatched week metadata does not affect valid Today data',
    () {
      for (final weekStart in ['2026-09-15', '2026-09-07', 'not-a-date']) {
        final profile = _profile({'weekStartDate': weekStart});
        expect(
          _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
          isNull,
        );
        expect(
          _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
          isNull,
        );
        expect(
          _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
          600,
        );
      }
    },
  );

  test(
    'legacy rolling-seven-day score cannot masquerade as a calendar-week score',
    () {
      final legacy = _sharedJson()
        ..remove('statsDate')
        ..remove('weekStartDate')
        ..remove('hasStepsRecord')
        ..remove('weeklyStepsRecordedDays')
        ..remove('weekScoreRecordedDays');
      final profile = SocialProfile.fromJson(legacy);
      expect(
        _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
        isNull,
      );
      // Legacy positive steps were already published for Monday through today.
      expect(
        _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
        1200,
      );
      expect(
        _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
        600,
      );
    },
  );

  test('legacy zero steps remain unknown without explicit coverage', () {
    final legacy = _sharedJson()
      ..remove('hasStepsRecord')
      ..remove('weeklyStepsRecordedDays')
      ..['todaySteps'] = 0
      ..['weeklySteps'] = 0;
    final profile = SocialProfile.fromJson(legacy);
    expect(
      _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
      isNull,
    );
    expect(
      _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
      isNull,
    );
  });

  test(
    'a weekly score requires recorded days even when its numeric value exists',
    () {
      for (final coverage in [null, 0, -1, 8, 'two']) {
        final profile = _profile({'weekScoreRecordedDays': coverage});
        expect(
          _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
          isNull,
        );
        expect(
          _value(profile, LeaderboardPeriod.today, LeaderboardMetric.score),
          75,
        );
      }
    },
  );

  test(
    'malformed remote metrics cannot become a ranked zero or inflated score',
    () {
      for (final invalid in [-1, 100.5, 101, double.infinity, '99']) {
        final profile = _profile({'todayScore': invalid, 'weekScore': invalid});
        expect(
          _value(profile, LeaderboardPeriod.today, LeaderboardMetric.score),
          isNull,
        );
        expect(
          _value(profile, LeaderboardPeriod.week, LeaderboardMetric.score),
          isNull,
        );
      }
      for (final invalid in [null, -1, 1.5, double.nan, '600']) {
        final profile = _profile({
          'todaySteps': invalid,
          'weeklySteps': invalid,
        });
        expect(
          _value(profile, LeaderboardPeriod.today, LeaderboardMetric.steps),
          isNull,
        );
        expect(
          _value(profile, LeaderboardPeriod.week, LeaderboardMetric.steps),
          isNull,
        );
      }
    },
  );
}
