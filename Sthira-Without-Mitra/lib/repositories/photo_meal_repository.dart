import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_meal_log.dart';

class PhotoMealRepository {
  PhotoMealRepository({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documentsDirectory;
  late Isar _isar;
  late String _baseDir;
  int _generation = 0;
  String _scope(Isar database) =>
      base64Url.encode(utf8.encode(database.name)).replaceAll('=', '');
  void _assertOwner(Isar database, int generation) {
    if (generation != _generation ||
        !identical(database, _isar) ||
        !database.isOpen)
      throw StateError('The active account changed. Please try again.');
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    final generation = ++_generation;
    final base = kIsWeb
        ? 'trufit_meal_photos'
        : p.join((await _documentsDirectory()).path, 'trufit_meal_photos');
    if (!kIsWeb)
      await Directory(
        p.join(base, 'accounts', _scope(isar)),
      ).create(recursive: true);
    _assertOwner(isar, generation);
    _baseDir = base;
  }

  Future<ScannedMealLog> saveScannedMeal({
    required String date,
    required String sourcePhotoPath,
    required String mealType,
    required String foodName,
    required int estimatedCalories,
    required double proteinGrams,
    required double carbsGrams,
    required double fatGrams,
    required double portionMultiplier,
  }) async {
    if (DateTime.tryParse(date) == null ||
        date.contains('/') ||
        date.contains('\\'))
      throw ArgumentError('Invalid meal date');
    if (estimatedCalories < 0 ||
        [
          proteinGrams,
          carbsGrams,
          fatGrams,
        ].any((value) => !value.isFinite || value < 0) ||
        !portionMultiplier.isFinite ||
        portionMultiplier <= 0)
      throw ArgumentError('Invalid meal nutrition');
    final database = _isar, generation = _generation;
    final base = _baseDir;
    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final uuidStr = const Uuid().v4();
    final extension = p
        .extension(sourcePhotoPath)
        .replaceFirst('.', '')
        .toLowerCase();
    final ext = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final relPath =
        'accounts/${_scope(database)}/${date}_${timestampMs}_$uuidStr.$ext';
    final destPath = kIsWeb ? sourcePhotoPath : p.join(base, relPath);

    File? copiedFile;
    if (!kIsWeb) {
      copiedFile = await File(sourcePhotoPath).copy(destPath);
    }

    final storedPath = kIsWeb ? destPath : relPath;

    final log = ScannedMealLog(
      id: 'photo_meal_${timestampMs}_$uuidStr',
      date: date,
      photoPath: storedPath,
      mealType: mealType,
      foodName: foodName,
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      portionMultiplier: portionMultiplier,
      timestamp: DateTime.now().toIso8601String(),
    );

    try {
      _assertOwner(database, generation);
      await database.writeTxn(() async {
        _assertOwner(database, generation);
        await database.scannedMealLogs.put(log);
        _assertOwner(database, generation);
      });
    } catch (e) {
      if (copiedFile != null && await copiedFile.exists()) {
        try {
          await copiedFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
    return log;
  }

  String getAbsolutePath(String storedPath) {
    final normalized = storedPath.replaceAll('\\', '/');
    if (normalized.split('/').contains('..'))
      throw ArgumentError('Path traversal detected');
    if (kIsWeb) return storedPath;
    if (p.isAbsolute(storedPath) ||
        p.windows.isAbsolute(storedPath) ||
        p.posix.isAbsolute(storedPath)) {
      const marker = 'trufit_meal_photos/';
      if (normalized.contains(marker))
        return p.join(_baseDir, normalized.split(marker).last);
      return storedPath;
    }
    return p.join(_baseDir, normalized);
  }

  List<ScannedMealLog> getScannedMealsForDate(String date) {
    return _isar.scannedMealLogs
        .filter()
        .dateEqualTo(date)
        .sortByTimestampDesc()
        .findAllSync();
  }

  int getTotalScannedCaloriesForDate(String date) {
    final meals = getScannedMealsForDate(date);
    return meals.fold(0, (sum, m) => sum + m.totalCalories);
  }

  Future<void> deleteScannedMeal(String id) async {
    final database = _isar, generation = _generation;
    final log = await database.scannedMealLogs
        .where()
        .idEqualTo(id)
        .findFirst();
    _assertOwner(database, generation);
    if (log == null) return;
    final absolute = getAbsolutePath(log.photoPath);
    await database.writeTxn(() async {
      _assertOwner(database, generation);
      await database.scannedMealLogs.delete(log.idInternal);
      _assertOwner(database, generation);
    });
    if (!kIsWeb) {
      final file = File(absolute);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }
}
