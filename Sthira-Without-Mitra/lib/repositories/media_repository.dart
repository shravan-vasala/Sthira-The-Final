import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/progress_photo.dart';
import '../models/daily_meal_log.dart';
import '../models/scanned_meal_log.dart';
import '../models/user_profile.dart';

class MediaRepository {
  MediaRepository({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;
  final Future<Directory> Function() _documentsDirectory;
  late Isar _isar;
  late String _baseDir;
  int _generation = 0;
  Isar get isar => _isar;
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
        ? 'trufit_media'
        : p.join((await _documentsDirectory()).path, 'trufit_media');
    if (!kIsWeb)
      await Directory(
        p.join(base, 'accounts', _scope(isar), 'progress_photos'),
      ).create(recursive: true);
    _assertOwner(isar, generation);
    _baseDir = base;
  }

  static void _validateDateAndWeight(String date, double? weight) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}' !=
            date)
      throw ArgumentError('Invalid photo date');
    if (weight != null && (!weight.isFinite || weight <= 0))
      throw ArgumentError('Weight must be positive');
  }

  // Save any media file to a given category subdirectory
  Future<String> saveMediaFile(String sourcePath, String category) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(category))
      throw ArgumentError('Invalid media category');
    final database = _isar, generation = _generation;
    final base = _baseDir;
    final extension = p
        .extension(sourcePath)
        .replaceFirst('.', '')
        .toLowerCase();
    final ext = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final relative =
        'accounts/${_scope(database)}/$category/${category}_${const Uuid().v4()}.$ext';
    if (kIsWeb) return sourcePath;
    final destination = File(p.join(base, relative));
    try {
      await destination.parent.create(recursive: true);
      _assertOwner(database, generation);
      await File(sourcePath).copy(destination.path);
      _assertOwner(database, generation);
      return relative;
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
  }

  // Save a progress photo from raw bytes (works on both web and mobile)
  Future<String> saveProgressPhoto(
    String date,
    Uint8List imageBytes, {
    String poseTag = 'none',
    double? weight,
    String? note,
  }) async {
    _validateDateAndWeight(date, weight);
    final database = _isar, generation = _generation;
    final base = _baseDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuidStr = const Uuid().v4();
    final relPath =
        'accounts/${_scope(database)}/progress_photos/${date}_${timestamp}_$uuidStr.jpg';
    final destPath = kIsWeb
        ? 'web_photo_${date}_${timestamp}_$uuidStr.jpg'
        : p.join(base, relPath);

    File? copiedFile;
    if (!kIsWeb) {
      copiedFile = File(destPath);
      await copiedFile.writeAsBytes(imageBytes);
    }

    final storedPath = kIsWeb ? destPath : relPath;
    final meta = ProgressPhoto(
      path: storedPath,
      date: date,
      pose: poseTag,
      weight: weight,
      note: note,
    );
    try {
      _assertOwner(database, generation);
      await database.writeTxn(() async {
        _assertOwner(database, generation);
        await database.progressPhotos.put(meta);
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

    return storedPath;
  }

  // Save a progress photo from a file path (legacy, mobile-only)
  Future<String> saveProgressPhotoFromPath(
    String date,
    String sourcePath, {
    String poseTag = 'none',
    double? weight,
    String? note,
  }) async {
    _validateDateAndWeight(date, weight);
    final database = _isar, generation = _generation;
    final base = _baseDir;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuidStr = const Uuid().v4();
    final relPath =
        'accounts/${_scope(database)}/progress_photos/${date}_${timestamp}_$uuidStr.jpg';
    final destPath = kIsWeb ? sourcePath : p.join(base, relPath);

    File? copiedFile;
    if (!kIsWeb) {
      copiedFile = await File(sourcePath).copy(destPath);
    }

    final storedPath = kIsWeb ? destPath : relPath;
    final meta = ProgressPhoto(
      path: storedPath,
      date: date,
      pose: poseTag,
      weight: weight,
      note: note,
    );

    try {
      _assertOwner(database, generation);
      await database.writeTxn(() async {
        _assertOwner(database, generation);
        await database.progressPhotos.put(meta);
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

    return storedPath;
  }

  String getAbsolutePath(String storedPath) =>
      resolveMediaPath(_baseDir, storedPath);

  static String resolveMediaPath(String base, String storedPath) {
    final normalized = storedPath.replaceAll('\\', '/');
    if (normalized.split('/').contains('..'))
      throw ArgumentError('Path traversal detected');
    if (kIsWeb) return storedPath;
    if (p.isAbsolute(storedPath) ||
        p.windows.isAbsolute(storedPath) ||
        p.posix.isAbsolute(storedPath)) {
      // Legacy media can move with app documents; restored_media is already absolute.
      const marker = 'trufit_media/';
      if (normalized.contains(marker))
        return p.join(base, normalized.split(marker).last);
      return storedPath;
    }
    return p.join(base, normalized);
  }

  ProgressPhoto getProgressPhotoMeta(String date, String photoPath) {
    return _isar.progressPhotos
            .where()
            .pathEqualTo(photoPath)
            .findFirstSync() ??
        ProgressPhoto(path: photoPath, date: date, pose: 'none');
  }

  String getPoseTag(String photoPath) {
    return _isar.progressPhotos
            .where()
            .pathEqualTo(photoPath)
            .findFirstSync()
            ?.pose ??
        'none';
  }

  List<String> getProgressPhotos(String date) {
    return _isar.progressPhotos
        .filter()
        .dateEqualTo(date)
        .findAllSync()
        .map((p) => p.path)
        .toList();
  }

  List<MapEntry<String, List<String>>> getAllProgressPhotos() {
    final grouped = <String, List<String>>{};
    final allPhotos = _isar.progressPhotos.where().findAllSync();
    for (final photo in allPhotos) {
      grouped.putIfAbsent(photo.date, () => []).add(photo.path);
    }
    final result = grouped.entries.toList();
    result.sort((a, b) => b.key.compareTo(a.key));
    return result;
  }

  List<ProgressPhoto> getAllProgressPhotosDetailed() {
    return _isar.progressPhotos.where().sortByDateDesc().findAllSync();
  }

  int getAllPhotoCount() {
    return _isar.progressPhotos.where().countSync();
  }

  Future<void> deletePhoto(String date, String photoPath) async {
    final database = _isar, generation = _generation;
    final base = _baseDir;
    final absolute = resolveMediaPath(base, photoPath);
    final photo = database.progressPhotos
        .where()
        .pathEqualTo(photoPath)
        .findFirstSync();
    if (photo == null || photo.date != date) return;
    await database.writeTxn(() async {
      _assertOwner(database, generation);
      await database.progressPhotos.delete(photo.id);
      _assertOwner(database, generation);
    });
    if (!kIsWeb) {
      final file = File(absolute);
      if (await file.exists()) {
        // The record is already committed as deleted. Account changes or an
        // unreadable remaining record should only skip optional file cleanup.
        try {
          _assertOwner(database, generation);
          if (!_isReferenced(database, base, absolute)) await file.delete();
        } catch (error) {
          debugPrint('Progress photo file cleanup skipped: $error');
        }
      }
    }
  }

  // Restoring a backup intentionally keeps one file for shared media. Removing
  // a physique record must not remove a meal image, avatar or another photo.
  bool _isReferenced(Isar database, String base, String absolute) {
    bool matches(String? storedPath, {bool scannedMeal = false}) {
      if (storedPath == null || storedPath.isEmpty) return false;
      if (storedPath.startsWith('assets/') ||
          storedPath.startsWith('http://') ||
          storedPath.startsWith('https://')) {
        return false;
      }
      final normalized = storedPath.replaceAll('\\', '/');
      if (normalized.split('/').contains('..')) {
        // Invalid legacy references must not turn a metadata deletion into a
        // destructive guess about the file they might still use.
        return true;
      }
      String resolved;
      if (scannedMeal) {
        final scanBase = p.join(p.dirname(base), 'trufit_meal_photos');
        const marker = 'trufit_meal_photos/';
        if (p.isAbsolute(storedPath) ||
            p.windows.isAbsolute(storedPath) ||
            p.posix.isAbsolute(storedPath)) {
          resolved = normalized.contains(marker)
              ? p.join(scanBase, normalized.split(marker).last)
              : storedPath;
        } else {
          resolved = p.join(scanBase, normalized);
        }
      } else {
        resolved = resolveMediaPath(base, storedPath);
      }
      return p.equals(p.normalize(resolved), p.normalize(absolute));
    }

    if (database.progressPhotos.where().findAllSync().any(
      (photo) => matches(photo.path),
    )) {
      return true;
    }
    if (database.userProfiles.where().findAllSync().any(
      (profile) => matches(profile.photoPath),
    )) {
      return true;
    }
    for (final meal in database.dailyMealLogs.where().findAllSync()) {
      for (final slot in meal.customSlots.values) {
        if (matches(slot.photoPath) || slot.photoPaths.any(matches)) {
          return true;
        }
      }
    }
    return database.scannedMealLogs.where().findAllSync().any(
      (meal) => matches(meal.photoPath, scannedMeal: true),
    );
  }

  Future<void> deletePhotos(Map<String, List<String>> photosByDate) async {
    final database = _isar, generation = _generation;
    for (final entry in photosByDate.entries) {
      final date = entry.key;
      for (final path in entry.value) {
        _assertOwner(database, generation);
        await deletePhoto(date, path);
      }
    }
  }
}
