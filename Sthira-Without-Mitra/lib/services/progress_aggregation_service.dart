import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../screens/progress/progress_screen.dart'; // For MetricType and TimeRange

/// A recorded value on its actual day, retained even when the graph is grouped.
class ChartObservation {
  final DateTime date;
  final double value;

  const ChartObservation({required this.date, required this.value});
}

class ChartBucket {
  final DateTime startDate;
  final DateTime endDate;
  final double? average;
  final double? min;
  final double? max;
  final int validDaysCount;
  final int eligibleDaysCount;
  final int incompleteDaysCount;
  final bool isPartial;
  final List<ChartObservation> observations;

  ChartBucket({
    required this.startDate,
    required this.endDate,
    this.average,
    this.min,
    this.max,
    required this.validDaysCount,
    required this.eligibleDaysCount,
    this.incompleteDaysCount = 0,
    this.isPartial = false,
    this.observations = const [],
  });
}

class ProgressAggregationService {
  /// Aggregates daily logs into buckets depending on the TimeRange.
  static List<ChartBucket> aggregate({
    required List<DailyLog> logs,
    required List<DailyMealLog> mealLogs,
    required MetricType metric,
    required TimeRange range,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime today,
    required double heightInMeters,
    required bool useKg,
  }) {
    if (range == TimeRange.weekly || range == TimeRange.oneMonth) {
      return _buildDailyBuckets(
        logs,
        mealLogs,
        metric,
        rangeStart,
        rangeEnd,
        today,
        heightInMeters,
        useKg,
      );
    } else {
      // Keep weekly detail throughout long ranges, including a full year.
      return _buildWeeklyBuckets(
        logs,
        mealLogs,
        metric,
        rangeStart,
        rangeEnd,
        today,
        heightInMeters,
        useKg,
      );
    }
  }

  static double? _extractValue(
    DailyLog? log,
    DailyMealLog? mLog,
    MetricType metric,
    double heightInMeters,
    bool useKg,
  ) {
    double? val;
    switch (metric) {
      case MetricType.weight:
        if (log?.weight != null) {
          val = useKg ? log!.weight! : log!.weight! * 2.20462;
        }
        break;
      case MetricType.steps:
        val = log?.steps?.toDouble();
        break;
      case MetricType.sleep:
        val = log?.sleepHours;
        break;
      case MetricType.screenTime:
        if (log?.screenTimeMinutes != null) {
          val = log!.screenTimeMinutes! / 60.0;
        }
        break;
      case MetricType.bodyFat:
        val = log?.bodyFat;
        break;
      case MetricType.bmi:
        if (log?.weight != null &&
            heightInMeters > 0 &&
            heightInMeters.isFinite) {
          val = log!.weight! / (heightInMeters * heightInMeters);
        }
        break;
      case MetricType.calories:
        if (mLog != null &&
            mLog.loggedSlotsCount > 0 &&
            mLog.hasCompleteCalories) {
          val = mLog.totalCalories.toDouble();
        }
        break;
      case MetricType.protein:
        if (mLog != null && mLog.loggedSlotsCount > 0 && mLog.hasCompleteMacros) {
          val = mLog.totalProtein;
        }
        break;
    }
    if (val != null && (!val.isFinite || val < 0)) return null;
    return val;
  }

  static bool _incompleteNutrition(DailyMealLog? log, MetricType metric) =>
      log != null &&
      log.loggedSlotsCount > 0 &&
      ((metric == MetricType.calories && !log.hasCompleteCalories) ||
          (metric == MetricType.protein && !log.hasCompleteMacros));

  static List<ChartBucket> _buildDailyBuckets(
    List<DailyLog> logs,
    List<DailyMealLog> mealLogs,
    MetricType metric,
    DateTime start,
    DateTime end,
    DateTime today,
    double h,
    bool useKg,
  ) {
    final logsMap = {for (var l in logs) l.date: l};
    final mealMap = {for (var m in mealLogs) m.date: m};

    final buckets = <ChartBucket>[];

    // Iterate day by day
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      final dateStr =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final log = logsMap[dateStr];
      final mLog = mealMap[dateStr];

      final isEligible = !current.isAfter(
        DateTime(today.year, today.month, today.day),
      );
      final val = isEligible
          ? _extractValue(log, mLog, metric, h, useKg)
          : null;

      buckets.add(
        ChartBucket(
          startDate: current,
          endDate: current,
          average: val,
          min: val,
          max: val,
          validDaysCount: val != null ? 1 : 0,
          eligibleDaysCount: isEligible ? 1 : 0,
          incompleteDaysCount: isEligible && _incompleteNutrition(mLog, metric)
              ? 1
              : 0,
          isPartial: !isEligible,
          observations: val == null
              ? const []
              : [ChartObservation(date: current, value: val)],
        ),
      );

      current = DateTime(current.year, current.month, current.day + 1);
    }

    return buckets;
  }

  static List<ChartBucket> _buildWeeklyBuckets(
    List<DailyLog> logs,
    List<DailyMealLog> mealLogs,
    MetricType metric,
    DateTime start,
    DateTime end,
    DateTime today,
    double h,
    bool useKg,
  ) {
    final logsMap = {for (var l in logs) l.date: l};
    final mealMap = {for (var m in mealLogs) m.date: m};

    final buckets = <ChartBucket>[];

    // Find first Monday on or before start
    DateTime current = DateTime(start.year, start.month, start.day);
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      final DateTime weekStart = current;
      final DateTime weekEnd = DateTime(
        current.year,
        current.month,
        current.day + 6,
      );

      // Clip boundaries to the requested range
      final DateTime effectiveStart = weekStart.isBefore(start)
          ? DateTime(start.year, start.month, start.day)
          : weekStart;
      final DateTime effectiveEnd = weekEnd.isAfter(endDay) ? endDay : weekEnd;

      final List<double> values = [];
      final observations = <ChartObservation>[];
      int eligibleDays = 0;
      int incompleteDays = 0;

      DateTime d = DateTime(
        effectiveStart.year,
        effectiveStart.month,
        effectiveStart.day,
      );
      while (!d.isAfter(effectiveEnd)) {
        if (!d.isAfter(today)) {
          eligibleDays++;
          final dateStr =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (_incompleteNutrition(mealMap[dateStr], metric)) incompleteDays++;
          final val = _extractValue(
            logsMap[dateStr],
            mealMap[dateStr],
            metric,
            h,
            useKg,
          );
          if (val != null) {
            values.add(val);
            observations.add(ChartObservation(date: d, value: val));
          }
        }
        d = DateTime(d.year, d.month, d.day + 1);
      }

      double? avg;
      double? minVal;
      double? maxVal;
      if (values.isNotEmpty) {
        avg = values.reduce((a, b) => a + b) / values.length;
        minVal = values.reduce((a, b) => a < b ? a : b);
        maxVal = values.reduce((a, b) => a > b ? a : b);
      }

      final bool isPartial =
          weekEnd.isAfter(today) ||
          weekStart.isBefore(start) ||
          weekEnd.isAfter(endDay);

      buckets.add(
        ChartBucket(
          startDate: effectiveStart,
          endDate: effectiveEnd,
          average: avg,
          min: minVal,
          max: maxVal,
          validDaysCount: values.length,
          eligibleDaysCount: eligibleDays,
          incompleteDaysCount: incompleteDays,
          isPartial: isPartial,
          observations: List.unmodifiable(observations),
        ),
      );

      current = DateTime(current.year, current.month, current.day + 7);
    }

    return buckets;
  }
}
