import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_log.dart';
import '../models/exercise_log.dart';
import '../models/habit.dart';
import '../models/body_stats.dart';
import '../models/daily_meal_log.dart';

class CsvExportResult {
  final bool isSuccess;
  final String? filePath;
  final String? errorMessage;

  CsvExportResult({required this.isSuccess, this.filePath, this.errorMessage});
}

class CsvExportService {
  final Isar? Function()? _databaseResolver;
  final String? Function()? _accountIdResolver;
  CsvExportService({
    Isar? Function()? databaseResolver,
    String? Function()? accountIdResolver,
  }) : _databaseResolver = databaseResolver,
       _accountIdResolver = accountIdResolver;

  Isar? _resolveDatabase() {
    if (_databaseResolver != null) return _databaseResolver();
    final open = Isar.instanceNames
        .map(Isar.getInstance)
        .whereType<Isar>()
        .where((database) => database.isOpen)
        .toList();
    return open.length == 1 ? open.single : null;
  }

  void _assertOwner(Isar database, String? uid) {
    if (!database.isOpen ||
        !identical(_resolveDatabase(), database) ||
        _accountIdResolver?.call() != uid) {
      throw StateError('The active account changed. Please export again.');
    }
  }

  dynamic _sanitizeForCsv(dynamic value) {
    if (value is String) {
      final trimmed = value.trimLeft();
      if (trimmed.startsWith('=') ||
          trimmed.startsWith('+') ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('@') ||
          trimmed.startsWith('\t') ||
          trimmed.startsWith('\r') ||
          trimmed.startsWith('\n')) {
        return "'$value";
      }
    }
    return value;
  }

  bool _isWithinRange(
    String dateStr,
    DateTime? normalizedStart,
    DateTime? normalizedEnd,
  ) {
    if (normalizedStart == null || normalizedEnd == null) return true;
    try {
      final date = DateTime.parse(dateStr);
      // Ensure time component doesn't break comparisons
      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(normalizedStart) &&
          dateOnly.isBefore(normalizedEnd);
    } catch (_) {
      return false;
    }
  }

  Future<CsvExportResult> exportData(DateTime? startDate) async {
    try {
      final archive = Archive();

      Future<void> addCsv(String name, String? csvText) async {
        if (csvText == null || csvText.isEmpty) return;
        final bytes = utf8.encode(csvText);
        archive.addFile(ArchiveFile.bytes(name, bytes));
      }

      final isar = _resolveDatabase();
      final uid = _accountIdResolver?.call();
      if (isar == null)
        return CsvExportResult(
          isSuccess: false,
          errorMessage: 'An explicit active account database is required.',
        );

      DateTime? normalizedStart;
      DateTime? normalizedEnd;
      String rangeStr = 'All Time';
      int intendedDays = 0;

      if (startDate != null) {
        final now = DateTime.now();
        normalizedStart = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        normalizedEnd = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1)); // Exclusive
        intendedDays = normalizedEnd.difference(normalizedStart).inDays;
        rangeStr =
            '${normalizedStart.toIso8601String().split('T')[0]} to ${now.toIso8601String().split('T')[0]} ($intendedDays days)';
      }

      final startSnapshot = DateTime.now();

      final snapshot = await isar.txn(
        () async => [
          await _exportDailyLogs(isar, normalizedStart, normalizedEnd),
          await _exportExerciseLogs(isar, normalizedStart, normalizedEnd),
          await _exportHabitCompletions(isar, normalizedStart, normalizedEnd),
          await _exportBodyStats(isar, normalizedStart, normalizedEnd),
          await _exportMeals(isar, normalizedStart, normalizedEnd),
        ],
      );
      _assertOwner(isar, uid);
      final dailyResult = snapshot[0];
      final exerciseResult = snapshot[1];
      final habitsResult = snapshot[2];
      final bodyStatsResult = snapshot[3];
      final mealsResult = snapshot[4];

      await addCsv('daily_logs.csv', dailyResult['csv']);
      await addCsv('exercise_logs.csv', exerciseResult['csv']);
      await addCsv('habits.csv', habitsResult['csv']);
      await addCsv('body_stats.csv', bodyStatsResult['csv']);
      await addCsv('meals.csv', mealsResult['csv']);
      await addCsv('meal_items.csv', mealsResult['itemsCsv']);

      if (archive.isEmpty)
        return CsvExportResult(
          isSuccess: true,
          errorMessage: 'No records found for the selected time range.',
        );

      // Manifest
      final manifestJson = jsonEncode({
        "exportDate": startSnapshot.toIso8601String(),
        "range": rangeStr,
        "scope":
            "CSV Export is a snapshot of selected metrics and is NOT a restorable account backup.",
        "categories": {
          "dailyLogs": {
            "count": dailyResult['count'],
            "errors": dailyResult['errors'],
          },
          "exerciseLogs": {
            "count": exerciseResult['count'],
            "errors": exerciseResult['errors'],
          },
          "habits": {
            "count": habitsResult['count'],
            "errors": habitsResult['errors'],
          },
          "bodyStats": {
            "count": bodyStatsResult['count'],
            "errors": bodyStatsResult['errors'],
          },
          "meals": {
            "count": mealsResult['count'],
            "errors": mealsResult['errors'],
          },
          "mealItems": {
            "count": mealsResult['itemsCount'],
            "errors": mealsResult['itemsErrors'],
          },
        },
      });
      await addCsv('manifest.json', manifestJson);

      _assertOwner(isar, uid);
      final zipData = await compute(_compressExport, archive);
      _assertOwner(isar, uid);
      final tempDir = await getTemporaryDirectory();

      // Clean up exports older than 1 hour safely, avoiding collision
      try {
        final nowTime = DateTime.now();
        for (final file in tempDir.listSync()) {
          if (file is File &&
              file.path.contains('trufit_export_') &&
              file.path.endsWith('.zip')) {
            final stat = file.statSync();
            if (nowTime.difference(stat.modified).inHours >= 1) {
              file.deleteSync();
            }
          }
        }
      } catch (_) {}

      final fileName =
          'trufit_export_${startSnapshot.microsecondsSinceEpoch}.zip';
      final zipFile = File('${tempDir.path}/$fileName');
      await zipFile.writeAsBytes(zipData);
      try {
        _assertOwner(isar, uid);
      } catch (_) {
        await zipFile.delete();
        rethrow;
      }

      return CsvExportResult(isSuccess: true, filePath: zipFile.path);
    } catch (e) {
      return CsvExportResult(
        isSuccess: false,
        errorMessage: 'Export failed: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _exportDailyLogs(
    Isar isar,
    DateTime? start,
    DateTime? end,
  ) async {
    final logs = await isar.dailyLogs.where().findAll();
    final rows = <List<dynamic>>[];
    int errors = 0;

    rows.add(
      [
        'Date',
        'Weight (kg)',
        'Steps',
        'Steps Source',
        'Sleep Hours',
        'Sleep Source',
        'Body Fat',
        'Workout Completed',
        'Workout Day ID',
        'Water (ml)',
        'Screen Time (mins)',
        'Updated At',
        'Day Feeling',
        'Day Note',
        'Check-in Updated At',
      ].map(_sanitizeForCsv).toList(),
    );

    for (final log in logs) {
      try {
        if (!_isWithinRange(log.date, start, end)) continue;
        rows.add(
          [
            log.date,
            log.weight ?? '',
            log.steps ?? '',
            log.stepsSource ?? '',
            log.sleepHours ?? '',
            log.sleepSource ?? '',
            log.bodyFat ?? '',
            log.workoutCompleted,
            log.workoutDayId ?? '',
            log.waterMl ?? '',
            log.screenTimeMinutes ?? '',
            log.updatedAt?.toIso8601String() ?? '',
            log.dayFeeling ?? '',
            log.dayNote ?? '',
            log.checkInUpdatedAt?.toIso8601String() ?? '',
          ].map(_sanitizeForCsv).toList(),
        );
      } catch (_) {
        errors++;
      }
    }

    return {
      'csv': rows.length > 1 ? csv.encode(rows) : null,
      'count': rows.length > 1 ? rows.length - 1 : 0,
      'errors': errors,
    };
  }

  Future<Map<String, dynamic>> _exportExerciseLogs(
    Isar isar,
    DateTime? start,
    DateTime? end,
  ) async {
    final logs = await isar.exerciseLogs.where().findAll();
    final rows = <List<dynamic>>[];
    int errors = 0;

    rows.add(
      [
        'Date',
        'Exercise ID',
        'Exercise Name',
        'Set',
        'Reps',
        'Weight (kg)',
        'Duration (seconds)',
      ].map(_sanitizeForCsv).toList(),
    );

    for (final log in logs) {
      try {
        if (!_isWithinRange(log.date, start, end)) continue;
        for (final set in log.sets) {
          rows.add(
            [
              log.date,
              log.instanceId,
              log.exerciseName,
              set.setNumber,
              set.reps,
              set.weight,
              set.durationSeconds ?? '',
            ].map(_sanitizeForCsv).toList(),
          );
        }
      } catch (_) {
        errors++;
      }
    }

    return {
      'csv': rows.length > 1 ? csv.encode(rows) : null,
      'count': rows.length > 1 ? rows.length - 1 : 0,
      'errors': errors,
    };
  }

  Future<Map<String, dynamic>> _exportHabitCompletions(
    Isar isar,
    DateTime? start,
    DateTime? end,
  ) async {
    final completions = await isar.habitCompletions.where().findAll();
    final habitList = await isar.habits.where().findAll();

    final habits = <String, Habit>{};
    for (final h in habitList) {
      habits[h.id] = h;
    }

    final rows = <List<dynamic>>[];
    int errors = 0;
    rows.add(
      [
        'Date',
        'Habit ID',
        'Habit Name',
        'Type',
        'Unit',
        'Value',
        'Override',
      ].map(_sanitizeForCsv).toList(),
    );

    for (final completion in completions) {
      try {
        if (!_isWithinRange(completion.date, start, end)) continue;

        final allKeys = <String>{
          ...completion.completions.keys,
          ...completion.overrides.keys,
        };
        for (final habitId in allKeys) {
          final habitName = habits[habitId]?.name ?? 'Unknown Habit ($habitId)';
          final habitType = habits[habitId]?.type ?? '';
          final unit = habits[habitId]?.unit ?? '';
          final val = completion.completions[habitId] ?? '';
          final override = completion.overrides[habitId] ?? '';

          rows.add(
            [
              completion.date,
              habitId,
              habitName,
              habitType,
              unit,
              val,
              override,
            ].map(_sanitizeForCsv).toList(),
          );
        }
      } catch (_) {
        errors++;
      }
    }

    return {
      'csv': rows.length > 1 ? csv.encode(rows) : null,
      'count': rows.length > 1 ? rows.length - 1 : 0,
      'errors': errors,
    };
  }

  Future<Map<String, dynamic>> _exportBodyStats(
    Isar isar,
    DateTime? start,
    DateTime? end,
  ) async {
    final statsList = await isar.bodyStats.where().findAll();
    final rows = <List<dynamic>>[];
    int errors = 0;

    rows.add(
      [
        'Date',
        'Unit',
        'Waist',
        'Hips',
        'Chest',
        'Left Arm',
        'Right Arm',
        'Left Thigh',
        'Right Thigh',
        'Neck',
      ].map(_sanitizeForCsv).toList(),
    );

    for (final stats in statsList) {
      try {
        if (!_isWithinRange(stats.date, start, end)) continue;
        rows.add(
          [
            stats.date,
            stats.unit,
            stats.waist ?? '',
            stats.hips ?? '',
            stats.chest ?? '',
            stats.leftArm ?? '',
            stats.rightArm ?? '',
            stats.leftThigh ?? '',
            stats.rightThigh ?? '',
            stats.neck ?? '',
          ].map(_sanitizeForCsv).toList(),
        );
      } catch (_) {
        errors++;
      }
    }

    return {
      'csv': rows.length > 1 ? csv.encode(rows) : null,
      'count': rows.length > 1 ? rows.length - 1 : 0,
      'errors': errors,
    };
  }

  Future<Map<String, dynamic>> _exportMeals(
    Isar isar,
    DateTime? start,
    DateTime? end,
  ) async {
    final logs = await isar.dailyMealLogs.where().findAll();
    final mealRows = <List<dynamic>>[];
    final itemRows = <List<dynamic>>[];
    int mealErrs = 0;
    int itemErrs = 0;

    mealRows.add(
      [
        'Date',
        'Slot',
        'Total Calories',
        'Total Protein (g)',
        'Total Carbs (g)',
        'Total Fat (g)',
        'Calories Complete',
        'Macros Complete',
      ].map(_sanitizeForCsv).toList(),
    );
    itemRows.add(
      [
        'Date',
        'Slot',
        'Item Name',
        'Portion',
        'Calories',
        'Protein (g)',
        'Carbs (g)',
        'Fat (g)',
        'Provenance',
        'Resolved',
        'Macros Known',
      ].map(_sanitizeForCsv).toList(),
    );

    for (final log in logs) {
      try {
        if (!_isWithinRange(log.date, start, end)) continue;

        for (final entry in log.customSlots.entries) {
          final slotName = entry.key;
          final slot = entry.value;

          if (slot.totalCalories > 0 || slot.items.isNotEmpty) {
            mealRows.add(
              [
                log.date,
                slotName,
                slot.totalCalories,
                slot.hasCompleteMacros ? slot.knownProtein : '',
                slot.hasCompleteMacros ? slot.knownCarbs : '',
                slot.hasCompleteMacros ? slot.knownFat : '',
                slot.hasCompleteCalories,
                slot.hasCompleteMacros,
              ].map(_sanitizeForCsv).toList(),
            );
          }

          for (final item in slot.items) {
            final known = slot.hasKnownMacrosFor(item);
            try {
              itemRows.add(
                [
                  log.date,
                  slotName,
                  item.name,
                  item.portion,
                  item.computedNutrition?.kcal,
                  known ? item.computedNutrition?.proteinG : '',
                  known ? item.computedNutrition?.carbsG : '',
                  known ? item.computedNutrition?.fatG : '',
                  item.provenance,
                  item.resolved,
                  known,
                ].map(_sanitizeForCsv).toList(),
              );
            } catch (_) {
              itemErrs++;
            }
          }
        }
      } catch (_) {
        mealErrs++;
      }
    }

    return {
      'csv': mealRows.length > 1 ? csv.encode(mealRows) : null,
      'count': mealRows.length > 1 ? mealRows.length - 1 : 0,
      'errors': mealErrs,
      'itemsCsv': itemRows.length > 1 ? csv.encode(itemRows) : null,
      'itemsCount': itemRows.length > 1 ? itemRows.length - 1 : 0,
      'itemsErrors': itemErrs,
    };
  }
}

List<int> _compressExport(Archive archive) => ZipEncoder().encode(archive);
