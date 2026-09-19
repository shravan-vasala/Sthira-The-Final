import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/progress_insight_service.dart';
import 'package:trufit_bodamma/services/progress_aggregation_service.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';

List<ChartBucket> days(DateTime start, List<double?> values) => [
  for (var i = 0; i < values.length; i++)
    ChartBucket(
      startDate: start.add(Duration(days: i)),
      endDate: start.add(Duration(days: i)),
      average: values[i],
      min: values[i],
      max: values[i],
      validDaysCount: values[i] == null ? 0 : 1,
      eligibleDaysCount: 1,
      observations: values[i] == null
          ? const []
          : [
              ChartObservation(
                date: start.add(Duration(days: i)),
                value: values[i]!,
              ),
            ],
    ),
];

ChartBucket bucketGroup(
  DateTime start,
  List<double?> values, {
  bool retainObservations = true,
}) {
  final readings = days(start, values).expand((b) => b.observations).toList();
  return ChartBucket(
    startDate: start,
    endDate: start.add(Duration(days: values.length - 1)),
    average: readings.isEmpty
        ? null
        : readings.fold<double>(0, (sum, o) => sum + o.value) / readings.length,
    validDaysCount: readings.length,
    eligibleDaysCount: values.length,
    observations: retainObservations ? readings : const [],
  );
}

MetricInsight insight({
  MetricType metric = MetricType.steps,
  TimeRange range = TimeRange.oneMonth,
  required List<ChartBucket> current,
  List<ChartBucket> previous = const [],
  double? target,
  DateTime? today,
  bool useKg = true,
}) => ProgressInsightService.buildInsight(
  metric: metric,
  range: range,
  currentBuckets: current,
  previousBuckets: previous,
  useKg: useKg,
  targetValue: target,
  today: today,
);

void main() {
  group('Truthful chart summaries', () {
    test('body hero retains actual latest measurement through aggregation', () {
      final result = insight(
        metric: MetricType.weight,
        range: TimeRange.threeMonths,
        current: [
          bucketGroup(DateTime(2024, 1, 1), [80, null, 79, null, 77]),
        ],
      );
      expect(result.heroValue, 77);
      expect(result.heroDate, DateTime(2024, 1, 5));
      expect(result.heroLabel, 'latest kg');
      expect(result.stats[0].value, '80.0 kg');
      expect(result.stats[1].value, '77.0 kg');
      expect(result.stats[2].value, '\u22123.0 kg');
      expect(result.coverageText, '3 measurements in this range');
    });

    test('aggregate without observations is honestly labelled an average', () {
      final result = insight(
        metric: MetricType.weight,
        current: [
          bucketGroup(DateTime(2024, 1, 1), [
            80,
            78,
            76,
          ], retainObservations: false),
        ],
      );
      expect(result.heroValue, 78);
      expect(result.heroDate, isNull);
      expect(result.heroLabel, contains('average'));
      expect(result.stats[0].value, '\u2014');
      expect(result.stats[2].value, 'Need another entry');
    });

    test('single body reading does not imply zero change', () {
      final result = insight(
        metric: MetricType.bodyFat,
        current: days(DateTime(2024, 1, 1), [21.5, null, null]),
      );
      expect(result.stats[2].value, 'Need another entry');
      expect(result.insightText, contains('another measurement'));
    });

    test('body fat change is percentage points, not percent', () {
      final result = insight(
        metric: MetricType.bodyFat,
        current: days(DateTime(2024, 1, 1), [21.5, 20.5]),
      );
      expect(result.stats[2].value, '\u22121.0 pp');
    });

    test('weighted daily average does not average bucket averages', () {
      final result = insight(
        current: [
          bucketGroup(DateTime(2024, 1, 1), [1000]),
          bucketGroup(DateTime(2024, 1, 2), [4000, 4000, 4000]),
        ],
      );
      expect(result.heroValue, 3250);
      expect(result.stats[0].value, '13,000 steps');
    });

    test('recorded zeros count while missing days do not dilute averages', () {
      final result = insight(
        current: days(DateTime(2024, 1, 1), [0, null, 6000]),
      );
      expect(result.heroValue, 3000);
      expect(result.coverageText, '2 of 3 days recorded');
    });

    test('duration summary uses hours and minutes and coverage', () {
      final result = insight(
        metric: MetricType.sleep,
        current: days(DateTime(2024, 1, 1), [7.5, 8.25, null]),
      );
      expect(result.heroLabel, 'avg hrs / night');
      expect(result.stats[0].value, '7h 30m');
      expect(result.stats[1].value, '8h 15m');
      expect(result.stats[2].value, '2 of 3');
    });

    test('aggregate means cannot be called a highest day', () {
      final result = insight(
        current: [
          bucketGroup(DateTime(2024, 1, 1), [
            1000,
            6000,
          ], retainObservations: false),
        ],
      );
      expect(result.stats[1].label, 'Highest day');
      expect(result.stats[1].value, '\u2014');
    });

    test('empty data has no fabricated value or comparison', () {
      final result = insight(current: days(DateTime(2024, 1, 1), [null, null]));
      expect(result.heroValue, isNull);
      expect(result.insightText, isNull);
      expect(result.coverageText, '0 of 2 days recorded');
    });
  });

  group('Target context and coverage', () {
    test(
      'calories above target receive neutral wording and incomplete-log context',
      () {
        final result = insight(
          metric: MetricType.calories,
          target: 2000,
          current: days(DateTime(2024, 1, 1), [2300, 2300, 2300]),
        );
        expect(
          result.insightText,
          'Logged average is 300 kcal above your current 2,000 kcal target.',
        );
        expect(result.heroLabel, 'avg logged kcal / day');
        expect(
          result.coverageText,
          contains('logged intake may be incomplete'),
        );
        expect(result.insightText, isNot(contains('hit')));
        expect(result.stats[1].label, 'Current target');
      },
    );

    test(
      'steps counts actual goal days rather than treating weekly means as daily hits',
      () {
        final result = insight(
          target: 10000,
          current: [
            bucketGroup(DateTime(2024, 1, 1), [0, 20000, 0, 20000]),
          ],
        );
        expect(result.stats[1].value, '2 of 4 days');
        expect(
          result.insightText,
          contains('current 10,000 steps target on 2 of 4 recorded days'),
        );
      },
    );

    test('protein reports logged intake against current target', () {
      final result = insight(
        metric: MetricType.protein,
        target: 100,
        current: days(DateTime(2024, 1, 1), [90, 110, null]),
      );
      expect(
        result.insightText,
        contains(
          'Logged protein reaches your current 100.0 g target on 1 of 2 recorded days',
        ),
      );
      expect(result.coverageText, contains('2 of 3 days with food logs'));
    });

    test('invalid targets never appear in user-facing output', () {
      final result = insight(
        metric: MetricType.calories,
        target: double.infinity,
        current: days(DateTime(2024, 1, 1), [2000]),
      );
      expect(result.stats[1].value, 'Not set');
      expect(result.insightText, isNull);
    });
  });

  group('Comparable periods', () {
    test('sparse previous period cannot produce a confident change', () {
      final result = insight(
        current: days(DateTime(2024, 2, 1), List.filled(7, 6000)),
        previous: days(DateTime(2024, 1, 25), [
          1000,
          null,
          null,
          null,
          null,
          null,
          null,
        ]),
      );
      expect(result.insightText, isNull);
    });

    test('sparse current period cannot produce a confident change', () {
      final result = insight(
        current: days(DateTime(2024, 2, 1), [
          6000,
          null,
          null,
          null,
          null,
          null,
          null,
        ]),
        previous: days(DateTime(2024, 1, 25), List.filled(7, 1000)),
      );
      expect(result.insightText, isNull);
    });

    test(
      'rolling-range comparisons refer to previous period rather than calendar month',
      () {
        final result = insight(
          current: days(DateTime(2024, 2, 14), List.filled(30, 7500)),
          previous: days(DateTime(2024, 1, 15), List.filled(30, 6000)),
        );
        expect(
          result.insightText,
          'Daily average is 25% higher than the previous period.',
        );
      },
    );

    test('weekly body measurements remain a useful cadence', () {
      final current = List<double?>.filled(28, null);
      final previous = List<double?>.filled(28, null);
      for (var i = 0; i < 28; i += 7) {
        current[i] = 75;
        previous[i] = 76.2;
      }
      final result = insight(
        metric: MetricType.weight,
        current: days(DateTime(2024, 2, 1), current),
        previous: days(DateTime(2024, 1, 4), previous),
      );
      expect(
        result.insightText,
        'Latest measurement is 1.2 kg lower than 25 Jan 2024.',
      );
    });

    test(
      'body observations clustered in one day do not represent a long period',
      () {
        final current = List<double?>.filled(28, null);
        final previous = List<double?>.filled(28, null);
        for (var i = 0; i < 4; i++) {
          current[i] = 75;
          previous[i] = 76.2;
        }
        final result = insight(
          metric: MetricType.weight,
          current: days(DateTime(2024, 2, 1), current),
          previous: days(DateTime(2024, 1, 4), previous),
        );
        expect(result.insightText, isNull);
      },
    );

    test('zero baseline reports absolute difference instead of Infinity', () {
      final result = insight(
        current: days(DateTime(2024, 2, 1), List.filled(7, 6000)),
        previous: days(DateTime(2024, 1, 25), List.filled(7, 0)),
      );
      expect(
        result.insightText,
        'Daily average is 6,000 steps higher than the previous period.',
      );
      expect(result.insightText, isNot(contains('Infinity')));
    });

    test('today stays in hero but is excluded from fair daily comparisons', () {
      final result = insight(
        today: DateTime(2024, 2, 7, 14),
        current: days(DateTime(2024, 2, 1), [
          6000,
          6000,
          6000,
          6000,
          6000,
          6000,
          0,
        ]),
        previous: days(DateTime(2024, 1, 25), List.filled(7, 6000)),
      );
      expect(result.heroValue, closeTo(36000 / 7, .001));
      expect(
        result.insightText,
        'Average over completed days is unchanged from the previous period.',
      );
      expect(result.coverageText, contains('includes today so far'));
    });

    test('today exclusion also works inside grouped weekly buckets', () {
      final result = insight(
        today: DateTime(2024, 2, 7),
        current: [
          bucketGroup(DateTime(2024, 2, 1), [
            6000,
            6000,
            6000,
            6000,
            6000,
            6000,
            0,
          ]),
        ],
        previous: [bucketGroup(DateTime(2024, 1, 25), List.filled(7, 6000))],
      );
      expect(
        result.insightText,
        startsWith('Average over completed days is unchanged'),
      );
    });

    test(
      'nutrition comparison distinguishes completed-day average from live hero',
      () {
        final result = insight(
          metric: MetricType.calories,
          today: DateTime(2024, 2, 7, 12),
          current: days(DateTime(2024, 2, 1), [
            2400,
            2400,
            2400,
            2400,
            2400,
            2400,
            300,
          ]),
          previous: days(DateTime(2024, 1, 25), List.filled(7, 2000)),
        );
        expect(result.heroValue, 2100);
        expect(
          result.insightText,
          'Logged average over completed days is 20% higher than the previous period.',
        );
        expect(result.coverageText, contains('includes today so far'));
      },
    );

    test('nutrition comparison retains logged qualifier', () {
      final result = insight(
        metric: MetricType.calories,
        current: days(DateTime(2024, 2, 1), List.filled(7, 2400)),
        previous: days(DateTime(2024, 1, 25), List.filled(7, 2000)),
      );
      expect(
        result.insightText,
        'Logged daily average is 20% higher than the previous period.',
      );
    });
  });
}
