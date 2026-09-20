import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/insight.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/insights_provider.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/utils/time_utils.dart';

final _today = DateTime(2026, 9, 19, 12);
DailyLog _day(int daysAgo, {int? steps, double? sleep, int? water}) => DailyLog(
  date: todayKey(DateTime(2026, 9, 19 - daysAgo)),
  steps: steps,
  sleepHours: sleep,
  waterMl: water,
);
DailyMealLog _food(int daysAgo, {bool complete = true}) => DailyMealLog(
  date: todayKey(DateTime(2026, 9, 19 - daysAgo)),
  customSlots: {
    'lunch': MealSlotLog(
      totalCalories: 400,
      totalProtein: 20,
      caloriesComplete: true,
      macrosComplete: complete,
    ),
  },
);
List<DailyLog> _paired({
  int longerSteps = 9000,
  int shorterSteps = 6000,
  double shorterSleep = 6,
}) => [
  for (var i = 1; i <= 5; i++) _day(i, steps: longerSteps, sleep: 8),
  for (var i = 6; i <= 10; i++)
    _day(i, steps: shorterSteps, sleep: shorterSleep),
];

class _Daily extends DailyLogRepository {
  _Daily(this.logs);
  List<DailyLog> logs;
  (String, String)? queriedRange;
  @override
  List<DailyLog> getLogsInRange(String start, String end) {
    queriedRange = (start, end);
    // Deliberately include out-of-range fixtures to exercise the provider guard.
    return List.of(logs);
  }
}

class _Meals extends MealRepository {
  _Meals(this.logs);
  List<DailyMealLog> logs;
  (String, String)? queriedRange;
  @override
  List<DailyMealLog> getLogsInRange(String start, String end) {
    queriedRange = (start, end);
    return List.of(logs);
  }
}

class _Harness {
  _Harness({
    List<DailyLog> logs = const [],
    List<DailyMealLog> meals = const [],
  }) : daily = _Daily(logs),
       food = _Meals(meals) {
    container = ProviderContainer(
      overrides: [
        dailyLogRepoProvider.overrideWithValue(daily),
        mealRepoProvider.overrideWithValue(food),
        dailyLogsUpdateProvider.overrideWith((ref) => dailyUpdates.stream),
        dailyMealLogsUpdateProvider.overrideWith((ref) => mealUpdates.stream),
        clockProvider.overrideWith((ref) => now),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await dailyUpdates.close();
      await mealUpdates.close();
    });
  }
  final _Daily daily;
  final _Meals food;
  final dailyUpdates = StreamController<void>.broadcast();
  final mealUpdates = StreamController<void>.broadcast();
  DateTime now = _today;
  late final ProviderContainer container;
  List<Insight> get insights => container.read(insightsProvider);
}

void main() {
  for (final scenario in [
    (now: DateTime(2026, 9, 20), range: '13\u201319 Sep 2026'),
    (now: DateTime(2026, 10, 3), range: '26 Sep\u20132 Oct 2026'),
    (now: DateTime(2027, 1, 4), range: '28 Dec 2026\u20133 Jan 2027'),
  ]) {
    test(
      'completed step coverage uses an unambiguous range ending ${scenario.now}',
      () {
        final harness = _Harness(
          logs: [
            for (var i = 1; i <= 7; i++)
              DailyLog(
                date: todayKey(
                  DateTime(
                    scenario.now.year,
                    scenario.now.month,
                    scenario.now.day - i,
                  ),
                ),
                steps: 8440,
              ),
          ],
        )..now = scenario.now;
        final insight = harness.insights.single;
        expect(insight.description, '8,440 steps/day on average');
        expect(
          insight.supportingText,
          '${scenario.range} \u00b7 All 7 completed days recorded',
        );
      },
    );
  }

  test('partial coverage keeps missing readings out of a nonzero average', () {
    final harness = _Harness(
      logs: [
        _day(1, steps: 1000),
        _day(2, steps: 2000),
        _day(3, steps: 3000),
        _day(4, steps: 6000),
        _day(5, water: 2000),
      ],
    );
    final insight = harness.insights.single;
    expect(insight.description, '3,000 steps/day on average');
    expect(
      insight.supportingText,
      '12\u201318 Sep 2026 \u00b7 4 of 7 completed days recorded. Missing days are excluded.',
    );
  });

  test('missing step readings cannot become a low-activity warning', () {
    final harness = _Harness(
      logs: [for (var i = 1; i <= 7; i++) _day(i, water: 2500)],
    );
    expect(harness.insights, isEmpty);
  });
  test(
    'last stored records are not mistaken for the last seven calendar days',
    () {
      final harness = _Harness(
        logs: [for (var i = 60; i < 67; i++) _day(i, steps: 12000)],
      );
      expect(harness.insights, isEmpty);
      expect(harness.daily.queriedRange, ('2026-08-20', '2026-09-18'));
    },
  );
  test(
    'real zero readings count and missing days stay outside the average',
    () {
      final harness = _Harness(
        logs: [
          for (var i = 1; i <= 4; i++) _day(i, steps: 0),
          _day(5, water: 2000),
        ],
      );
      final insight = harness.insights.single;
      expect(insight.description, '0 steps/day on average');
      expect(insight.supportingText, contains('4 of 7 completed days'));
      expect(insight.supportingText, contains('Missing days are excluded.'));
      expect(insight.supportingText, contains('12\u201318 Sep 2026'));
      expect(insight.severity, InsightSeverity.neutral);
    },
  );
  test(
    'fewer than four observed days leave room for Coach instead of a thin trend',
    () {
      final harness = _Harness(
        logs: [
          for (var i = 1; i <= 3; i++) _day(i, steps: 12000),
          for (var i = 15; i < 20; i++) _day(i, steps: 12000),
        ],
      );
      expect(harness.insights, isEmpty);
    },
  );
  test(
    'today and future readings do not contribute to completed-day trends',
    () {
      final harness = _Harness(
        logs: [
          _day(0, steps: 30000),
          for (var i = -1; i >= -7; i--) _day(i, steps: 30000),
          for (var i = 1; i <= 3; i++) _day(i, steps: 1000),
        ],
      );
      expect(harness.insights, isEmpty);
    },
  );
  test(
    'paired sleep association states actual averages, sample sizes and noncausal context',
    () {
      final harness = _Harness(logs: _paired());
      final insight = harness.insights.first;
      expect(insight.id, 'corr_sleep_steps');
      expect(insight.description, contains('9,000 steps'));
      expect(insight.description, contains('versus 6,000'));
      expect('(5 days)'.allMatches(insight.description).length, 2);
      expect(insight.description, contains('20 Aug\u201318 Sep 2026'));
      expect(insight.description, contains('Other factors may contribute'));
      expect(insight.severity, InsightSeverity.neutral);
    },
  );
  test(
    'unrelated logs cannot satisfy paired-observation evidence threshold',
    () {
      final harness = _Harness(
        logs: [
          _day(1, steps: 12000, sleep: 8),
          _day(2, steps: 2000, sleep: 6),
          for (var i = 3; i <= 10; i++) _day(i, water: 2000),
        ],
      );
      expect(harness.insights, isEmpty);
    },
  );
  test('recorded zero sleep and steps remain valid paired observations', () {
    final harness = _Harness(
      logs: _paired(longerSteps: 1000, shorterSteps: 0, shorterSleep: 0),
    );
    final insight = harness.insights.firstWhere(
      (item) => item.id == 'corr_sleep_steps',
    );
    expect(insight.description, contains('versus 0'));
    expect(insight.description, isNot(contains('Infinity')));
    expect(insight.description, isNot(contains('NaN')));
  });
  test(
    'future, partial today and invalid sleep or dates do not contaminate the association',
    () {
      final baseline = _Harness(logs: _paired()).insights.first.description;
      final harness = _Harness(
        logs: [
          ..._paired(),
          _day(0, steps: 99999, sleep: 10),
          _day(-1, steps: 99999, sleep: 10),
          _day(11, steps: 99999, sleep: double.nan),
          _day(12, steps: -100, sleep: 8),
          _day(13, steps: 99999, sleep: 25),
          // Dart normalizes this to 14 September unless the key is checked.
          DailyLog(date: '2026-08-45', steps: 99999, sleepHours: 10),
        ],
      );
      expect(harness.insights.first.description, baseline);
    },
  );
  test(
    'an old association expires even inside the thirty-day query window',
    () {
      final logs = [
        for (var i = 15; i < 20; i++) _day(i, steps: 9000, sleep: 8),
        for (var i = 20; i < 25; i++) _day(i, steps: 6000, sleep: 6),
      ];
      expect(_Harness(logs: logs).insights, isEmpty);
    },
  );
  test(
    'generic complete nutrition does not mask a supported movement insight',
    () {
      final harness = _Harness(logs: _paired(), meals: [_food(0)]);
      expect(harness.insights.first.id, 'corr_sleep_steps');
      expect(
        harness.insights.any((item) => item.id == 'nutrition_analysis'),
        isFalse,
      );
      expect(_Harness(meals: [_food(0)]).insights, isEmpty);
    },
  );
  test('stale nutrition does not keep the daily Coach slot occupied', () {
    final harness = _Harness(meals: [_food(5, complete: false)]);
    expect(harness.insights, isEmpty);
    expect(harness.food.queriedRange, ('2026-09-18', '2026-09-19'));
  });
  test(
    'an empty latest meal row cannot hide the latest actual nutrition gap',
    () {
      final harness = _Harness(
        meals: [
          DailyMealLog(date: '2026-09-19'),
          _food(1, complete: false),
        ],
      );
      final insight = harness.insights.single;
      expect(insight.id, 'nutrition_analysis');
      expect(insight.description, contains('18 Sep 2026'));
      expect(insight.severity, InsightSeverity.neutral);
    },
  );
  test(
    'fresh actionable nutrition can precede yesterday movement evidence',
    () {
      final harness = _Harness(
        logs: _paired(),
        meals: [_food(0, complete: false)],
      );
      expect(harness.insights.first.id, 'nutrition_analysis');
    },
  );
  test(
    'clock rollover includes newly completed days and expires older nutrition',
    () {
      final harness = _Harness(
        logs: [for (var i = 0; i <= 3; i++) _day(i, steps: 4000)],
        meals: [_food(1, complete: false)],
      );
      expect(harness.insights.single.id, 'nutrition_analysis');
      harness.now = DateTime(2026, 9, 20);
      harness.container.invalidate(clockProvider);
      expect(harness.insights.single.id, 'trend_steps_recorded');
      expect(
        harness.insights.single.supportingText,
        contains('13\u201319 Sep 2026'),
      );
    },
  );
  test(
    'Home historical browsing does not relabel the current evidence window',
    () {
      final harness = _Harness(logs: _paired());
      final before = harness.insights.first.description;
      harness.container.read(selectedDateProvider.notifier).state = DateTime(
        2024,
      );
      expect(harness.insights.first.description, before);
    },
  );
  test('account rebinding removes previously cached insights', () {
    final harness = _Harness(
      logs: _paired(),
      meals: [_food(0, complete: false)],
    );
    expect(harness.insights, isNotEmpty);
    harness.daily.logs = [];
    harness.food.logs = [];
    harness.container.read(accountGenerationProvider.notifier).state++;
    expect(harness.insights, isEmpty);
  });
  test(
    'repository signals refresh evidence without changing the selected date',
    () async {
      final harness = _Harness();
      final changed = Completer<List<Insight>>();
      final subscription = harness.container.listen(insightsProvider, (
        _,
        next,
      ) {
        if (next.isNotEmpty && !changed.isCompleted) changed.complete(next);
      });
      addTearDown(subscription.close);
      expect(harness.insights, isEmpty);
      harness.daily.logs = _paired();
      harness.dailyUpdates.add(null);
      expect(
        (await changed.future.timeout(const Duration(seconds: 2))).first.id,
        'corr_sleep_steps',
      );
    },
  );
}
