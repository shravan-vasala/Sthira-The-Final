import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/progress_chart_provider.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.profile);
  final UserProfile profile;

  @override
  UserProfile build() => profile;
}

ProviderContainer _container({
  required UserProfile profile,
  List<DailyLog>? logs,
}) {
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(() => _Profile(profile)),
      dailyLogsRangeProvider.overrideWith((ref, dates) {
        expect(dates, ('2026-09-01', '2026-09-07'));
        return logs ?? [DailyLog(date: '2026-09-01', weight: 80)];
      }),
      dailyMealLogsRangeProvider.overrideWith((ref, dates) {
        expect(dates, ('2026-09-01', '2026-09-07'));
        return [];
      }),
      clockProvider.overrideWithValue(DateTime(2026, 9, 7, 15)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final args = (
    metric: MetricType.bmi,
    range: TimeRange.weekly,
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 7),
  );

  for (final entry in <String, double?>{
    'missing': null,
    'zero': 0,
    'negative': -180,
    'NaN': double.nan,
    'infinite': double.infinity,
  }.entries) {
    test(
      '${entry.key} height leaves BMI unrecorded instead of inferring a value',
      () {
        final container = _container(profile: UserProfile(height: entry.value));
        final buckets = container.read(aggregatedChartProvider(args));

        expect(buckets, hasLength(7));
        expect(buckets.every((b) => b.average == null), isTrue);
        expect(buckets.every((b) => b.validDaysCount == 0), isTrue);
        expect(buckets.expand((b) => b.observations), isEmpty);
        expect(buckets.fold(0, (sum, b) => sum + b.eligibleDaysCount), 7);
      },
    );
  }

  test(
    'explicit height derives BMI from canonical kg even with lb display',
    () {
      final container = _container(
        profile: UserProfile(height: 200, useKg: false),
      );
      final buckets = container.read(aggregatedChartProvider(args));

      expect(buckets.first.average, 20);
      expect(buckets.first.observations.single.value, 20);
      expect(buckets.first.observations.single.date, DateTime(2026, 9, 1));
      expect(buckets.skip(1).every((b) => b.average == null), isTrue);
    },
  );

  test('grouped BMI keeps actual reading dates and values', () {
    final container = _container(
      profile: UserProfile(height: 200),
      logs: [
        DailyLog(date: '2026-09-01', weight: 80),
        DailyLog(date: '2026-09-05', weight: 76),
      ],
    );
    final buckets = container.read(
      aggregatedChartProvider((
        metric: MetricType.bmi,
        range: TimeRange.threeMonths,
        start: args.start,
        end: args.end,
      )),
    );
    final readings = buckets.expand((b) => b.observations).toList();

    expect(buckets.first.average, 19.5);
    expect(readings.map((o) => o.value), [20, 19]);
    expect(readings.map((o) => o.date), [
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 5),
    ]);
    expect(buckets.last.average, isNull);
  });

  test('missing height does not suppress recorded weight', () {
    final container = _container(profile: UserProfile());
    final buckets = container.read(
      aggregatedChartProvider((
        metric: MetricType.weight,
        range: args.range,
        start: args.start,
        end: args.end,
      )),
    );

    expect(buckets.first.average, 80);
    expect(buckets.first.observations.single.value, 80);
    expect(buckets.first.observations.single.date, DateTime(2026, 9, 1));
  });
}
