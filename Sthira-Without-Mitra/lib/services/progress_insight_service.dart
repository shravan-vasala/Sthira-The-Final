import 'dart:math' as math;

import 'package:intl/intl.dart';
import '../screens/progress/progress_screen.dart';
import 'progress_aggregation_service.dart';

class MetricSummaryStat {
  final String label;
  final String value;

  const MetricSummaryStat({required this.label, required this.value});
}

class MetricInsight {
  final double? heroValue;
  final String heroLabel;
  final DateTime? heroDate;
  final String? insightText;
  final String coverageText;
  final List<MetricSummaryStat> stats;

  const MetricInsight({
    this.heroValue,
    required this.heroLabel,
    this.heroDate,
    this.insightText,
    this.coverageText = '',
    this.stats = const [],
  });
}

/// Describes recorded data without treating missing days as zero or inferring
/// that a food log represents an entire day's intake.
class ProgressInsightService {
  static bool _isBody(MetricType metric) =>
      metric == MetricType.weight ||
      metric == MetricType.bodyFat ||
      metric == MetricType.bmi;

  static bool _isNutrition(MetricType metric) =>
      metric == MetricType.calories || metric == MetricType.protein;

  static bool _accumulatesToday(MetricType metric) =>
      metric == MetricType.steps ||
      metric == MetricType.screenTime ||
      _isNutrition(metric);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<ChartObservation> _observations(List<ChartBucket> buckets) {
    final result = <ChartObservation>[];
    for (final bucket in buckets) {
      if (bucket.observations.isNotEmpty) {
        result.addAll(bucket.observations.where((o) => o.value.isFinite));
      } else if (bucket.validDaysCount == 1 &&
          _sameDay(bucket.startDate, bucket.endDate) &&
          bucket.average != null) {
        // Daily fixtures and older callers still identify an exact observation.
        result.add(
          ChartObservation(date: bucket.startDate, value: bucket.average!),
        );
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  static List<ChartBucket> _valid(List<ChartBucket> buckets) =>
      buckets
          .where(
            (b) =>
                b.average != null &&
                b.average!.isFinite &&
                b.validDaysCount > 0,
          )
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  static int _count(List<ChartBucket> buckets) =>
      buckets.fold(0, (sum, b) => sum + b.validDaysCount);

  static int _eligible(List<ChartBucket> buckets) =>
      buckets.fold(0, (sum, b) => sum + b.eligibleDaysCount);

  static double? _average(List<ChartBucket> buckets) {
    final count = _count(buckets);
    if (count == 0) return null;
    return buckets.fold<double>(
          0,
          (sum, b) => sum + b.average! * b.validDaysCount,
        ) /
        count;
  }

  static String _unit(MetricType metric, bool useKg) => switch (metric) {
    MetricType.weight => useKg ? 'kg' : 'lb',
    MetricType.steps => 'steps',
    MetricType.sleep || MetricType.screenTime => 'hrs',
    MetricType.bodyFat => '%',
    MetricType.calories => 'kcal',
    MetricType.protein => 'g',
    MetricType.bmi => '',
  };

  static String _format(double value, MetricType metric, bool useKg) {
    if (metric == MetricType.sleep || metric == MetricType.screenTime) {
      final minutes = (value * 60).round();
      final hours = minutes ~/ 60;
      final remainder = minutes % 60;
      if (hours == 0) return '$remainder min';
      if (remainder == 0) return '${hours}h';
      return '${hours}h ${remainder}m';
    }
    final number = metric == MetricType.steps || metric == MetricType.calories
        ? NumberFormat('#,##0').format(value.round())
        : value.toStringAsFixed(1);
    final unit = _unit(metric, useKg);
    return unit.isEmpty ? number : '$number $unit';
  }

  static String _delta(double value, MetricType metric, bool useKg) =>
      metric == MetricType.bodyFat
      ? '${value.toStringAsFixed(1)} pp'
      : _format(value, metric, useKg);

  static String _date(DateTime date) => DateFormat('d MMM yyyy').format(date);

  /// Comparisons use completed days for metrics that accumulate throughout the
  /// day. A grouped average can only be adjusted when its observations exist.
  static List<ChartBucket> _comparisonBuckets(
    List<ChartBucket> buckets,
    MetricType metric,
    DateTime? today,
  ) {
    if (today == null || !_accumulatesToday(metric)) return buckets;
    final cutoff = DateTime(today.year, today.month, today.day);
    final result = <ChartBucket>[];
    for (final bucket in buckets) {
      if (bucket.endDate.isBefore(cutoff)) {
        result.add(bucket);
        continue;
      }
      if (!bucket.startDate.isBefore(cutoff)) continue;
      final observations = _observations([
        bucket,
      ]).where((o) => o.date.isBefore(cutoff)).toList();
      // Do not compare an unadjustable aggregate containing today's partial log.
      if (bucket.observations.isEmpty && bucket.validDaysCount > 0) continue;
      final eligible = math.min(
        bucket.eligibleDaysCount,
        cutoff.difference(bucket.startDate).inDays,
      );
      result.add(
        ChartBucket(
          startDate: bucket.startDate,
          endDate: cutoff.subtract(const Duration(days: 1)),
          average: observations.isEmpty
              ? null
              : observations.fold<double>(0, (sum, o) => sum + o.value) /
                    observations.length,
          validDaysCount: observations.length,
          eligibleDaysCount: eligible,
          observations: observations,
        ),
      );
    }
    return result;
  }

  static bool _enoughForComparison(
    List<ChartBucket> buckets,
    MetricType metric,
  ) {
    final eligible = _eligible(buckets);
    final count = _count(_valid(buckets));
    if (eligible == 0) return false;
    if (_isBody(metric)) {
      // Weekly measurements are a useful cadence; daily weigh-ins are not
      // required. Both periods must independently meet this evidence threshold.
      final minimum = math.max(1, eligible ~/ 7);
      if (count < minimum) return false;
      final readings = _observations(_valid(buckets));
      if (readings.length < minimum) return false;
      if (minimum > 1 &&
          readings.last.date.difference(readings.first.date).inDays <
              math.min(7, eligible ~/ 2)) {
        return false;
      }
      return true;
    }
    final minimum = math.max(3, (eligible * .5).ceil());
    return count >= minimum;
  }

  static MetricInsight buildInsight({
    required MetricType metric,
    required TimeRange range,
    required List<ChartBucket> currentBuckets,
    required List<ChartBucket> previousBuckets,
    required bool useKg,
    double? targetValue,
    DateTime? today,
  }) {
    final current = _valid(currentBuckets);
    final observations = _observations(current);
    final count = _count(current);
    final eligible = _eligible(currentBuckets);
    final average = _average(current);
    final body = _isBody(metric);
    final nutrition = _isNutrition(metric);
    final target =
        targetValue != null && targetValue.isFinite && targetValue > 0
        ? targetValue
        : null;
    final latest = observations.isEmpty ? null : observations.last;
    final hero = body
        ? latest?.value ?? (current.isEmpty ? null : current.last.average)
        : average;
    final unit = _unit(metric, useKg);
    final heroLabel = body
        ? latest != null
              ? (unit.isEmpty ? 'latest measurement' : 'latest $unit')
              : 'latest period average${unit.isEmpty ? '' : ' ($unit)'}'
        : nutrition
        ? 'avg logged $unit / day'
        : metric == MetricType.sleep
        ? 'avg hrs / night'
        : 'avg $unit / day';
    final noun = body
        ? (count == 1 ? 'measurement' : 'measurements')
        : metric == MetricType.sleep
        ? (eligible == 1 ? 'night' : 'nights')
        : eligible == 1
        ? 'day'
        : 'days';
    var coverage = body
        ? '$count $noun in this range'
        : '$count of $eligible $noun ${nutrition ? 'with food logs' : 'recorded'}';
    if (today != null &&
        _accumulatesToday(metric) &&
        observations.any((o) => _sameDay(o.date, today))) {
      coverage += ' \u00b7 includes today so far';
    }
    if (nutrition) {
      final incompleteDays = currentBuckets.fold<int>(
        0,
        (sum, bucket) => sum + bucket.incompleteDaysCount,
      );
      if (incompleteDays > 0) {
        coverage +=
            ' \u00b7 $incompleteDays ${incompleteDays == 1 ? 'day' : 'days'} excluded: ${metric == MetricType.protein ? 'macros' : 'calories'} incomplete';
      }
      coverage += ' \u00b7 logged intake may be incomplete';
    }

    final stats = <MetricSummaryStat>[];
    void stat(String label, String value) =>
        stats.add(MetricSummaryStat(label: label, value: value));
    String formatted(double? value) =>
        value == null ? '\u2014' : _format(value, metric, useKg);
    final extrema = current
        .expand((b) => [b.min, b.max])
        .whereType<double>()
        .where((v) => v.isFinite)
        .toList();
    final values = observations.map((o) => o.value).toList();
    // Bucket means cannot stand in for daily highs and lows.
    final actualValues = [...values, ...extrema];
    final minimum = actualValues.isEmpty ? null : actualValues.reduce(math.min);
    final maximum = actualValues.isEmpty ? null : actualValues.reduce(math.max);
    if (body) {
      final first = observations.isEmpty ? null : observations.first;
      stat(
        first == null
            ? 'First measurement'
            : 'First \u00b7 ${DateFormat('d MMM').format(first.date)}',
        formatted(first?.value),
      );
      stat(
        latest == null
            ? 'Latest measurement'
            : 'Latest \u00b7 ${DateFormat('d MMM').format(latest.date)}',
        formatted(latest?.value),
      );
      final change = observations.length > 1
          ? latest!.value - first!.value
          : null;
      stat(
        'Change in range',
        change == null
            ? 'Need another entry'
            : '${change > 0
                  ? '+'
                  : change < 0
                  ? '\u2212'
                  : ''}${_delta(change.abs(), metric, useKg)}',
      );
    } else if (metric == MetricType.steps) {
      stat(
        'Recorded total',
        formatted(average == null ? null : average * count),
      );
      if (target != null && observations.length == count && count > 0) {
        final hits = observations.where((o) => o.value >= target).length;
        stat('At current goal', '$hits of $count days');
      } else {
        stat('Highest day', formatted(maximum));
      }
      stat('Recorded days', '$count of $eligible');
    } else if (metric == MetricType.sleep || metric == MetricType.screenTime) {
      stat(
        metric == MetricType.sleep ? 'Shortest night' : 'Lowest day',
        formatted(minimum),
      );
      stat(
        metric == MetricType.sleep ? 'Longest night' : 'Highest day',
        formatted(maximum),
      );
      stat(
        metric == MetricType.sleep ? 'Recorded nights' : 'Recorded days',
        '$count of $eligible',
      );
    } else {
      stat('Logged average', formatted(average));
      stat('Current target', target == null ? 'Not set' : formatted(target));
      stat('Days with food logs', '$count of $eligible');
    }

    String? insight;
    final comparableCurrent = _comparisonBuckets(currentBuckets, metric, today);
    final comparablePrevious = _comparisonBuckets(
      previousBuckets,
      metric,
      today,
    );
    if (_enoughForComparison(comparableCurrent, metric) &&
        _enoughForComparison(comparablePrevious, metric)) {
      final currentReadings = _observations(_valid(comparableCurrent));
      final previousReadings = _observations(_valid(comparablePrevious));
      final a = body
          ? currentReadings.last.value
          : _average(_valid(comparableCurrent))!;
      final b = body
          ? previousReadings.last.value
          : _average(_valid(comparablePrevious))!;
      final delta = a - b;
      if (body) {
        insight = delta.abs() < .05
            ? 'Latest measurement is unchanged from ${_date(previousReadings.last.date)}.'
            : 'Latest measurement is ${metric == MetricType.bodyFat ? '${delta.abs().toStringAsFixed(1)} percentage points' : _delta(delta.abs(), metric, useKg)} ${delta > 0 ? 'higher' : 'lower'} than ${_date(previousReadings.last.date)}.';
      } else {
        final excludesToday =
            today != null &&
            _accumulatesToday(metric) &&
            observations.any((o) => _sameDay(o.date, today));
        final subject = excludesToday
            ? nutrition
                  ? 'Logged average over completed days'
                  : 'Average over completed days'
            : nutrition
            ? 'Logged daily average'
            : metric == MetricType.sleep
            ? 'Average sleep duration'
            : 'Daily average';
        if (delta.abs() < .01) {
          insight = '$subject is unchanged from the previous period.';
        } else if (b.abs() < .01) {
          insight =
              '$subject is ${_format(delta.abs(), metric, useKg)} ${delta > 0 ? 'higher' : 'lower'} than the previous period.';
        } else {
          final percent = (delta.abs() / b.abs() * 100).round();
          insight = percent == 0
              ? '$subject is less than 1% ${delta > 0 ? 'higher' : 'lower'} than the previous period.'
              : '$subject is $percent% ${delta > 0 ? 'higher' : 'lower'} than the previous period.';
        }
      }
    }
    if (insight == null && count > 0) {
      if (body && observations.length == 1) {
        insight = 'Add another measurement to see change across this range.';
      } else if ((metric == MetricType.steps || metric == MetricType.protein) &&
          target != null &&
          observations.length == count) {
        final hits = observations.where((o) => o.value >= target).length;
        insight =
            '${metric == MetricType.protein ? 'Logged protein' : 'Recorded steps'} reaches your current ${_format(target, metric, useKg)} target on $hits of $count recorded ${count == 1 ? 'day' : 'days'}.';
      } else if (metric == MetricType.calories &&
          target != null &&
          average != null) {
        final delta = average - target;
        insight = delta.abs() < .5
            ? 'Logged average matches your current ${formatted(target)} target.'
            : 'Logged average is ${formatted(delta.abs())} ${delta > 0 ? 'above' : 'below'} your current ${formatted(target)} target.';
      }
    }
    return MetricInsight(
      heroValue: hero,
      heroLabel: heroLabel,
      heroDate: body ? latest?.date : null,
      insightText: insight,
      coverageText: coverage,
      stats: List.unmodifiable(stats),
    );
  }
}
