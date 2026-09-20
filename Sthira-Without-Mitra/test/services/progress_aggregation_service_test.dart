import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/progress_aggregation_service.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';

void main() {
  group('ProgressAggregationService Tests', () {
    test(
      'Yearly weekly data retains a missing week, recorded zero and exact observation dates',
      () {
        final start = DateTime(2025, 9, 20);
        final end = DateTime(2026, 9, 19);
        final logs = <DailyLog>[];
        for (
          var d = start;
          !d.isAfter(end);
          d = DateTime(d.year, d.month, d.day + 1)
        ) {
          if (!d.isBefore(DateTime(2026, 5, 4)) &&
              !d.isAfter(DateTime(2026, 5, 10))) {
            continue;
          }
          logs.add(
            DailyLog(
              date:
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              steps: d == start ? 0 : 100,
            ),
          );
        }
        final buckets = ProgressAggregationService.aggregate(
          logs: logs,
          mealLogs: [],
          metric: MetricType.steps,
          range: TimeRange.twelveMonths,
          rangeStart: start,
          rangeEnd: end,
          today: end,
          heightInMeters: 1.8,
          useKg: true,
        );
        expect(buckets.length, inInclusiveRange(52, 54));
        expect(buckets.first.average, 50);
        expect(buckets.first.observations.first.value, 0);
        expect(buckets.first.observations.first.date, start);
        final gap = buckets.singleWhere(
          (b) => b.startDate == DateTime(2026, 5, 4),
        );
        expect(gap.average, isNull);
        expect(gap.validDaysCount, 0);
        expect(gap.eligibleDaysCount, 7);
        expect(buckets.fold(0, (n, b) => n + b.validDaysCount), logs.length);
        expect(buckets.fold(0, (n, b) => n + b.eligibleDaysCount), 365);
        expect(buckets.last.observations.last.date, end);
      },
    );

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    test('Scenario 1 & 2: Calendar-week boundaries and partial weeks', () {
      // 3M range (approx 90 days). Let's use a fixed start/end
      // 2024-01-01 was a Monday.
      final start = DateTime(2024, 1, 10); // Wednesday
      final end = DateTime(2024, 1, 31); // Wednesday

      final buckets = ProgressAggregationService.aggregate(
        logs: [],
        mealLogs: [],
        metric: MetricType.weight,
        range: TimeRange.threeMonths,
        rangeStart: start,
        rangeEnd: end,
        today: today,
        heightInMeters: 1.8,
        useKg: true,
      );

      // Buckets should start from the Monday of Jan 10th (which is Jan 8),
      // but clipped to effective start: Jan 10.
      expect(buckets.first.startDate, DateTime(2024, 1, 10));
      expect(buckets.first.endDate, DateTime(2024, 1, 14)); // Sunday
      expect(buckets.first.isPartial, true);

      // Last bucket should end on Jan 31
      expect(buckets.last.endDate, DateTime(2024, 1, 31));
      expect(buckets.last.isPartial, true);
    });

    test('Scenario 4: December/January boundaries and Leap Year', () {
      final start = DateTime(2023, 12, 15);
      final end = DateTime(2024, 3, 5); // 2024 is a leap year

      final buckets = ProgressAggregationService.aggregate(
        logs: [],
        mealLogs: [],
        metric: MetricType.weight,
        range: TimeRange.twelveMonths,
        rangeStart: start,
        rangeEnd: end,
        today: today,
        heightInMeters: 1.8,
        useKg: true,
      );

      expect(buckets.first.startDate, start);
      expect(buckets.first.endDate, DateTime(2023, 12, 17));
      expect(buckets.last.endDate, end);
      final leapWeek = buckets.singleWhere(
        (b) => b.startDate == DateTime(2024, 2, 26),
      );
      expect(leapWeek.endDate, DateTime(2024, 3, 3));
      expect(leapWeek.eligibleDaysCount, 7);
      expect(
        buckets.fold(0, (sum, b) => sum + b.eligibleDaysCount),
        end.difference(start).inDays + 1,
      );
      expect(
        buckets.every((b) => b.endDate.difference(b.startDate).inDays < 7),
        isTrue,
      );
    });

    test(
      'Scenario 5 & 6 & 11: Missing vs recorded-zero, Meal-only days, Empty gaps',
      () {
        final start = DateTime(2024, 5, 1);
        final end = DateTime(2024, 5, 3);

        final logs = [
          DailyLog(
            date: '2024-05-01',
            steps: 0,
            weight: 80.0,
          ), // Recorded zero steps
          // May 02 is totally missing DailyLog, but has a meal log
        ];
        final mealLogs = [
          DailyMealLog(
            date: '2024-05-02',
            customSlots: {'lunch': MealSlotLog(totalCalories: 1500)},
          ),
        ];

        // Check Steps (May 1 should have 0, May 2 should be null, May 3 null)
        final stepBuckets = ProgressAggregationService.aggregate(
          logs: logs,
          mealLogs: mealLogs,
          metric: MetricType.steps,
          range: TimeRange.weekly,
          rangeStart: start,
          rangeEnd: end,
          heightInMeters: 1.8,
          useKg: true,
          today: today,
        );
        expect(stepBuckets[0].average, 0.0);
        expect(stepBuckets[1].average, null); // gap

        // Check Calories (May 1 null, May 2 1500)
        final calBuckets = ProgressAggregationService.aggregate(
          logs: logs,
          mealLogs: mealLogs,
          metric: MetricType.calories,
          range: TimeRange.weekly,
          rangeStart: start,
          rangeEnd: end,
          heightInMeters: 1.8,
          useKg: true,
          today: today,
        );
        expect(calBuckets[0].average, null); // gap
        expect(calBuckets[1].average, 1500.0);
      },
    );

    test('Scenario 9: Canonical kg values and consistent lb display', () {
      final start = DateTime(2024, 5, 1);
      final logs = [DailyLog(date: '2024-05-01', weight: 100.0)]; // 100kg

      final bucketsKg = ProgressAggregationService.aggregate(
        logs: logs,
        mealLogs: [],
        metric: MetricType.weight,
        range: TimeRange.weekly,
        rangeStart: start,
        rangeEnd: start,
        heightInMeters: 1.8,
        useKg: true,
        today: today,
      );
      expect(bucketsKg.first.average, 100.0);

      final bucketsLb = ProgressAggregationService.aggregate(
        logs: logs,
        mealLogs: [],
        metric: MetricType.weight,
        range: TimeRange.weekly,
        rangeStart: start,
        rangeEnd: start,
        heightInMeters: 1.8,
        useKg: false,
        today: today,
      );
      expect(bucketsLb.first.average, closeTo(220.462, 0.001));
    });

    test('Scenario 12: Future days excluded from coverage', () {
      final start = today.subtract(const Duration(days: 2));
      final end = today.add(
        const Duration(days: 2),
      ); // Range extends into future

      final buckets = ProgressAggregationService.aggregate(
        logs: [],
        mealLogs: [],
        metric: MetricType.weight,
        range: TimeRange.threeMonths, // weekly buckets
        rangeStart: start,
        rangeEnd: end,
        heightInMeters: 1.8,
        useKg: true,
        today: today,
      );

      // The eligibleDaysCount should NOT include the future days.
      // If start is today-2, and end is today+2, there are 3 days up to today.
      // So eligibleDaysCount should be 3, not 5.
      final totalEligible = buckets.fold(
        0,
        (sum, b) => sum + b.eligibleDaysCount,
      );
      expect(totalEligible, 3);
    });

    test('Scenario 13: Nonfinite/invalid inputs for BMI', () {
      final start = DateTime(2024, 5, 1);
      final logs = [DailyLog(date: '2024-05-01', weight: 80.0)];

      // Height is 0 (invalid)
      final buckets = ProgressAggregationService.aggregate(
        logs: logs,
        mealLogs: [],
        metric: MetricType.bmi,
        range: TimeRange.weekly,
        rangeStart: start,
        rangeEnd: start,
        heightInMeters: 0.0,
        useKg: true,
        today: today,
      );

      // BMI should be null gracefully rather than Infinity or NaN
      expect(buckets.first.average, null);
    });

    test('Daily future days exclude both coverage and future records', () {
      final start = DateTime(2024, 5, 1);
      final buckets = ProgressAggregationService.aggregate(
        logs: [DailyLog(date: '2024-05-03', steps: 5000)],
        mealLogs: [],
        metric: MetricType.steps,
        range: TimeRange.weekly,
        rangeStart: start,
        rangeEnd: DateTime(2024, 5, 3),
        heightInMeters: 1.8,
        useKg: true,
        today: DateTime(2024, 5, 2),
      );
      expect(buckets.fold(0, (sum, b) => sum + b.eligibleDaysCount), 2);
      expect(buckets.last.average, isNull);
      expect(buckets.last.observations, isEmpty);
    });

    test(
      'Weekly aggregation retains dated measurements rather than only means',
      () {
        final buckets = ProgressAggregationService.aggregate(
          logs: [
            DailyLog(date: '2024-05-01', weight: 80),
            DailyLog(date: '2024-05-03', weight: 78),
          ],
          mealLogs: [],
          metric: MetricType.weight,
          range: TimeRange.threeMonths,
          rangeStart: DateTime(2024, 5, 1),
          rangeEnd: DateTime(2024, 5, 5),
          heightInMeters: 1.8,
          useKg: true,
          today: DateTime(2024, 5, 5),
        );
        expect(buckets.single.average, 79);
        expect(buckets.single.observations.map((o) => o.value), [80, 78]);
        expect(buckets.single.observations.last.date, DateTime(2024, 5, 3));
      },
    );

    test(
      'Yearly observations preserve weight unit conversion exactly once',
      () {
        final buckets = ProgressAggregationService.aggregate(
          logs: [DailyLog(date: '2024-05-03', weight: 100)],
          mealLogs: [],
          metric: MetricType.weight,
          range: TimeRange.twelveMonths,
          rangeStart: DateTime(2024, 5, 1),
          rangeEnd: DateTime(2024, 5, 5),
          heightInMeters: 1.8,
          useKg: false,
          today: DateTime(2024, 5, 5),
        );
        expect(
          buckets.single.observations.single.value,
          closeTo(220.462, .001),
        );
        expect(buckets.single.observations.single.date, DateTime(2024, 5, 3));
      },
    );

    test(
      'Nonfinite body measurements and infinite height never create fake observations',
      () {
        for (final metric in [MetricType.weight, MetricType.bmi]) {
          final buckets = ProgressAggregationService.aggregate(
            logs: [
              DailyLog(
                date: '2024-05-03',
                weight: metric == MetricType.weight ? double.nan : 80,
              ),
            ],
            mealLogs: [],
            metric: metric,
            range: TimeRange.weekly,
            rangeStart: DateTime(2024, 5, 3),
            rangeEnd: DateTime(2024, 5, 3),
            heightInMeters: double.infinity,
            useKg: true,
            today: DateTime(2024, 5, 5),
          );
          expect(buckets.single.average, isNull);
          expect(buckets.single.observations, isEmpty);
        }
      },
    );
  });
}
