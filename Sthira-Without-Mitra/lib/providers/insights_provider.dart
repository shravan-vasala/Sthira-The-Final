import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/insight.dart';
import 'app_providers.dart';
import '../utils/time_utils.dart';

DateTime? _recordedDay(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null || todayKey(parsed) != value) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _dateRange(DateTime start, DateTime end) {
  final first = DateFormat(
    start.year != end.year
        ? 'd MMM yyyy'
        : start.month != end.month
        ? 'd MMM'
        : 'd',
  ).format(start);
  return '$first\u2013${DateFormat('d MMM yyyy').format(end)}';
}

String _steps(double value) => NumberFormat('#,##0').format(value.round());

/// Recent descriptions of observed data, independent of Home's browsing date.
/// Missing records and today's accumulating step count cannot establish a trend.
final insightsProvider = Provider<List<Insight>>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(dailyMealLogsUpdateProvider);
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  final mealRepo = ref.watch(mealRepoProvider);
  final now = ref.watch(clockProvider);
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final weekStart = DateTime(today.year, today.month, today.day - 7);
  final monthStart = DateTime(today.year, today.month, today.day - 30);
  final candidates =
      <({Insight insight, DateTime observedThrough, int priority})>[];

  void add(Insight insight, DateTime observedThrough, int priority) {
    candidates.add((
      insight: insight,
      observedThrough: observedThrough,
      priority: priority,
    ));
  }

  // A completed food-count summary duplicates the Meals card. Surface only a
  // recent, actionable nutrition gap, using the latest actual food entry.
  final mealLogs =
      mealRepo.getLogsInRange(todayKey(yesterday), todayKey(today)).where((
        log,
      ) {
        final day = _recordedDay(log.date);
        return day != null &&
            !day.isBefore(yesterday) &&
            !day.isAfter(today) &&
            log.loggedSlotsCount > 0;
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
  if (mealLogs.isNotEmpty) {
    final latest = mealLogs.first;
    if (!latest.hasCompleteMacros || !latest.hasCompleteCalories) {
      final day = _recordedDay(latest.date)!;
      add(
        Insight(
          id: 'nutrition_analysis',
          type: InsightType.trend,
          title: 'Nutrition is incomplete',
          description:
              'Food logged on ${DateFormat('d MMM yyyy').format(day)} has incomplete nutrition. Review the recorded foods and portions before comparing with your targets.',
          severity: InsightSeverity.neutral,
          dateGenerated: now,
          icon: Icons.restaurant_rounded,
        ),
        day,
        3,
      );
    }
  }

  // Query a bounded calendar range rather than treating the last stored rows as
  // consecutive days. Filter again at the boundary to reject future/invalid data.
  final logs =
      dailyLogRepo
          .getLogsInRange(todayKey(monthStart), todayKey(yesterday))
          .where((log) {
            final day = _recordedDay(log.date);
            return day != null &&
                !day.isBefore(monthStart) &&
                !day.isAfter(yesterday);
          })
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final stepDays = logs
      .where(
        (log) =>
            log.steps != null &&
            log.steps! >= 0 &&
            !_recordedDay(log.date)!.isBefore(weekStart),
      )
      .toList();
  if (stepDays.length >= 4) {
    final average =
        stepDays.fold<double>(0, (sum, log) => sum + log.steps!) /
        stepDays.length;
    add(
      Insight(
        id: 'trend_steps_recorded',
        type: InsightType.trend,
        title: 'Your recent steps',
        description: '${_steps(average)} steps/day on average',
        supportingText:
            '${_dateRange(weekStart, yesterday)} \u00b7 '
            '${stepDays.length == 7 ? 'All 7 completed days recorded' : '${stepDays.length} of 7 completed days recorded. Missing days are excluded.'}',
        severity: InsightSeverity.neutral,
        dateGenerated: now,
        icon: Icons.directions_walk_rounded,
      ),
      _recordedDay(stepDays.last.date)!,
      1,
    );
  }

  final pairs = logs
      .where(
        (log) =>
            log.steps != null &&
            log.steps! >= 0 &&
            log.sleepHours != null &&
            log.sleepHours!.isFinite &&
            log.sleepHours! >= 0 &&
            log.sleepHours! <= 24,
      )
      .toList();
  final longerSleep = pairs.where((log) => log.sleepHours! >= 7.5).toList();
  final shorterSleep = pairs.where((log) => log.sleepHours! < 7.5).toList();
  if (longerSleep.length >= 5 &&
      shorterSleep.length >= 5 &&
      !_recordedDay(pairs.last.date)!.isBefore(weekStart)) {
    final longerAverage =
        longerSleep.fold<double>(0, (sum, log) => sum + log.steps!) /
        longerSleep.length;
    final shorterAverage =
        shorterSleep.fold<double>(0, (sum, log) => sum + log.steps!) /
        shorterSleep.length;
    if (longerAverage > shorterAverage &&
        longerAverage >= shorterAverage * 1.15) {
      add(
        Insight(
          id: 'corr_sleep_steps',
          type: InsightType.correlation,
          title: 'Sleep and recorded steps',
          description:
              'Paired logs from ${_dateRange(monthStart, yesterday)} show an average of ${_steps(longerAverage)} steps after 7.5h+ sleep (${longerSleep.length} days), versus ${_steps(shorterAverage)} after shorter sleep (${shorterSleep.length} days). Other factors may contribute.',
          severity: InsightSeverity.neutral,
          dateGenerated: now,
          icon: Icons.bedtime_rounded,
        ),
        _recordedDay(pairs.last.date)!,
        2,
      );
    }
  }

  candidates.sort((a, b) {
    final freshness = b.observedThrough.compareTo(a.observedThrough);
    return freshness != 0 ? freshness : b.priority.compareTo(a.priority);
  });
  return List.unmodifiable(candidates.map((candidate) => candidate.insight));
});
