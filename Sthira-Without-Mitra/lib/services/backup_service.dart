import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../models/friend.dart';
import '../models/user_profile.dart';
import '../models/sync_queue_item.dart';
import '../models/app_config.dart';
import '../models/daily_log.dart';
import '../models/habit.dart';
import '../models/meal_plan.dart';
import '../models/badge.dart';
import '../models/scanned_meal_log.dart';
import '../models/progress_photo.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/coach_note.dart';
import '../models/body_stats.dart';
import '../models/daily_meal_log.dart';
import '../models/user_food_log.dart';
import 'schema_migration_service.dart';
import 'backup_encryption_service.dart';
import '../interfaces/i_auth_service.dart';

class BackupRestoreResult {
  final bool success;

  /// A committed local restore must not be presented as if nothing changed when
  /// the subsequent sync reconciliation fails.
  final bool localCommitted;
  final int failedPhotosCount;
  final String? errorMessage;
  final String? safetyBackupPath;
  BackupRestoreResult({
    required this.success,
    this.localCommitted = false,
    this.failedPhotosCount = 0,
    this.errorMessage,
    this.safetyBackupPath,
  });
}

class BackupVerificationResult {
  final bool isValid;
  final int totalEntries;
  final int photoCount;
  final String? errorMessage;
  final bool isEncrypted;
  final int schemaVersion;
  final String appVersion;
  final String createdAt;
  BackupVerificationResult({
    required this.isValid,
    required this.totalEntries,
    required this.photoCount,
    this.errorMessage,
    this.isEncrypted = false,
    this.schemaVersion = 0,
    this.appVersion = 'Unknown',
    this.createdAt = 'Unknown',
  });
}

/// Complete local account snapshots. Preferences, credentials and disposable AI
/// caches are deliberately excluded. Restore replaces account records and drops
/// obsolete outgoing writes; the coordinator then rebuilds authoritative sync.
class BackupService {
  final IAuthService _auth;
  final Isar? Function()? _databaseResolver;
  final Future<void> Function(Isar)? _beforeRestore;
  final Future<void> Function(Isar, bool)? _afterRestore;
  bool _restoring = false;
  static const int _maxAutoBackups = 3;

  BackupService(
    this._auth, {
    Isar? Function()? databaseResolver,
    Future<void> Function(Isar)? beforeRestore,
    Future<void> Function(Isar, bool)? afterRestore,
  }) : _databaseResolver = databaseResolver,
       _beforeRestore = beforeRestore,
       _afterRestore = afterRestore;

  Isar _database() {
    final resolved = _databaseResolver?.call();
    if (_databaseResolver != null) {
      if (resolved == null || !resolved.isOpen)
        throw StateError('Account database unavailable.');
      return resolved;
    }
    final instances = Isar.instanceNames
        .map(Isar.getInstance)
        .whereType<Isar>()
        .where((db) => db.isOpen)
        .toList();
    if (instances.length != 1) {
      throw StateError('An explicit account database is required.');
    }
    return instances.single;
  }

  void _assertOwner(Isar database, String? uid) {
    if (!database.isOpen ||
        !identical(_database(), database) ||
        _auth.uid != uid) {
      throw StateError('The active account changed. Please try again.');
    }
  }

  String get accountScope => _scope(_auth.uid);
  String metadataKey(String key) => '${key}_$accountScope';

  Future<Map<String, Uint8List>> _snapshot(
    Isar database,
  ) => database.txn(() async {
    final result = <String, Uint8List>{};
    for (final entry in _collections(database).entries) {
      // Native export produces JSON bytes; decoding/encoding happens in the worker.
      result[entry.key] = await entry.value.where().exportJsonRaw(
        (bytes) => Uint8List.fromList(bytes),
      );
    }
    return result;
  });

  Future<String?> createBackup({
    String? password,
    bool includeMedia = true,
  }) async {
    if (kIsWeb || _restoring) return null;
    try {
      final database = _database();
      final uid = _auth.uid;
      return await _createPinned(
        database,
        uid,
        password: password,
        includeMedia: includeMedia,
      );
    } catch (error) {
      debugPrint('Backup creation failed: $error');
      return null;
    }
  }

  Future<String> _createPinned(
    Isar database,
    String? uid, {
    String? password,
    bool includeMedia = true,
  }) async {
    _assertOwner(database, uid);
    final directory = await getApplicationDocumentsDirectory();
    _assertOwner(database, uid);
    final snapshot = await _snapshot(database);
    _assertOwner(database, uid);
    final path = await compute(
      _createBackupArchive,
      _CreateRequest(snapshot, directory.path, uid, password, includeMedia),
    );
    try {
      _assertOwner(database, uid);
      return path;
    } catch (_) {
      await File(path).delete();
      rethrow;
    }
  }

  Future<BackupVerificationResult> verifyBackup(
    String path, {
    String? password,
  }) async {
    try {
      final uid = _auth.uid;
      final decoded = await compute(
        _readBackupArchive,
        _ReadRequest(path, password),
      );
      if (_auth.uid != uid) throw StateError('The active account changed.');
      _checkBackupOwner(decoded.manifest, uid);
      return BackupVerificationResult(
        isValid: true,
        totalEntries: decoded.totalEntries,
        photoCount: decoded.photos.length,
        isEncrypted: decoded.encrypted,
        schemaVersion: decoded.manifest['schemaVersion'] as int,
        appVersion: decoded.manifest['appVersion'] as String? ?? 'Unknown',
        createdAt: decoded.manifest['createdAt'] as String? ?? 'Unknown',
        errorMessage: decoded.missingMedia > 0
            ? '${decoded.missingMedia} referenced photos were not included in this backup.'
            : null,
      );
    } on _BackupFormatException catch (error) {
      return BackupVerificationResult(
        isValid: false,
        totalEntries: 0,
        photoCount: 0,
        isEncrypted: error.encrypted,
        errorMessage: error.message,
      );
    } catch (error) {
      return BackupVerificationResult(
        isValid: false,
        totalEntries: 0,
        photoCount: 0,
        errorMessage: error.toString(),
      );
    }
  }

  Future<BackupRestoreResult> restoreBackup(
    String path, {
    String? password,
  }) async {
    if (kIsWeb || _restoring)
      return BackupRestoreResult(
        success: false,
        errorMessage: 'A restore is already in progress or unavailable.',
      );
    _restoring = true;
    Isar? database;
    String? uid;
    String? safetyPath;
    Directory? restoredMedia;
    var coordinationStarted = false;
    var committed = false;
    var failedPhotos = 0;
    try {
      database = _database();
      uid = _auth.uid;
      if (uid != null && (_beforeRestore == null || _afterRestore == null)) {
        throw StateError(
          'Cloud sync coordination is required to restore a signed-in account.',
        );
      }
      final decoded = await compute(
        _readBackupArchive,
        _ReadRequest(path, password),
      );
      _assertOwner(database, uid);
      _checkBackupOwner(decoded.manifest, uid);
      coordinationStarted = true;
      await _beforeRestore?.call(database);
      _assertOwner(database, uid);
      // A readable, verified safety copy is mandatory before replacing any records.
      safetyPath = await _createPinned(database, uid, password: password);
      _assertOwner(database, uid);
      final directory = await getApplicationDocumentsDirectory();
      restoredMedia = Directory(
        p.join(
          directory.path,
          'restored_media',
          _scope(uid),
          DateTime.now().microsecondsSinceEpoch.toString(),
        ),
      );
      final prepared = await compute(
        _prepareRestore,
        _RestoreRequest(decoded, restoredMedia.path, directory.path),
      );
      failedPhotos = prepared.missingMedia;
      _assertOwner(database, uid);
      // All operations are synchronous in one native transaction. Any malformed
      // row/import error rolls the entire replacement back, including its queue.
      database.writeTxnSync(() {
        for (final entry in _collections(database!).entries) {
          entry.value.clearSync();
          entry.value.importJsonRawSync(prepared.data[entry.key]!);
          // Force model deserialization before commit as well: JSON-backed
          // properties and required fields must be readable, not merely storable.
          entry.value.where().findAllSync();
          if (entry.value.countSync() != prepared.counts[entry.key]) {
            throw const FormatException(
              'Duplicate or invalid records in backup.',
            );
          }
        }
        database.syncQueueItems.clearSync();
        if (uid != null) {
          database.appConfigs.putSync(
            AppConfig(key: 'restore_reconciliation_pending', value: uid),
          );
        }
      });
      committed = true;
      coordinationStarted = false;
      await _afterRestore?.call(database, true);
      return BackupRestoreResult(
        success: true,
        localCommitted: true,
        failedPhotosCount: failedPhotos,
        safetyBackupPath: safetyPath,
      );
    } catch (error) {
      debugPrint('Restore failed: $error');
      return BackupRestoreResult(
        success: false,
        localCommitted: committed,
        failedPhotosCount: failedPhotos,
        safetyBackupPath: safetyPath,
        errorMessage: committed
            ? 'Your local backup was restored, but cloud reconciliation needs attention. $error'
            : 'Restore stopped before replacing your data. $error',
      );
    } finally {
      if (coordinationStarted && database != null) {
        try {
          await _afterRestore?.call(database, committed);
        } catch (error) {
          debugPrint('Restore coordination cleanup failed: $error');
        }
      }
      if (!committed && restoredMedia != null && await restoredMedia.exists()) {
        await restoredMedia.delete(recursive: true);
      }
      _restoring = false;
    }
  }

  Future<void> autoBackup() async {
    if (kIsWeb || _restoring) return;
    try {
      final database = _database();
      final uid = _auth.uid;
      final scope = _scope(uid);
      final prefs = await SharedPreferences.getInstance();
      final dateKey = 'last_auto_backup_date_$scope';
      final last = DateTime.tryParse(prefs.getString(dateKey) ?? '');
      if (last != null && DateTime.now().difference(last).inDays < 7) return;
      _assertOwner(database, uid);
      final root = await getApplicationDocumentsDirectory();
      final directory = Directory(p.join(root.path, 'auto_backups', scope));
      await directory.create(recursive: true);
      final path = await _createPinned(database, uid, includeMedia: false);
      _assertOwner(database, uid);
      final destination = p.join(directory.path, p.basename(path));
      await File(path).copy(destination);
      await File(path).delete();
      _assertOwner(database, uid);
      await prefs.setString(dateKey, DateTime.now().toIso8601String());
      await prefs.setString(
        'last_auto_backup_display_$scope',
        DateFormat('MMM dd, yyyy').format(DateTime.now()),
      );
      final files = await directory
          .list()
          .where((entry) => entry is File && p.extension(entry.path) == '.zip')
          .cast<File>()
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      for (final file in files.take(
        (files.length - _maxAutoBackups).clamp(0, files.length),
      )) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Auto backup failed: $error');
    }
  }
}

String _scope(String? uid) => uid == null
    ? 'guest'
    : sha256.convert(utf8.encode(uid)).toString().substring(0, 24);

void _checkBackupOwner(Map<String, dynamic> manifest, String? uid) {
  final owner = manifest['uid'];
  if (owner != null && owner != uid) {
    throw const FormatException(
      'This backup belongs to a different account. Sign in to that account to restore it.',
    );
  }
}

Map<String, IsarCollection<dynamic>> _collections(Isar db) => {
  'userProfiles': db.userProfiles,
  'dailyLogs': db.dailyLogs,
  'habits': db.habits,
  'mealPlans': db.mealPlans,
  'badges': db.badges,
  'scannedMealLogs': db.scannedMealLogs,
  'progressPhotos': db.progressPhotos,
  'exerciseLogs': db.exerciseLogs,
  'exercisePrs': db.exercisePrs,
  'workoutPlans': db.workoutPlans,
  'workoutSessions': db.workoutSessions,
  'coachNotes': db.coachNotes,
  'bodyStats': db.bodyStats,
  'dailyMealLogs': db.dailyMealLogs,
  'habitCompletions': db.habitCompletions,
  'userFoodLogs': db.userFoodLogs,
  'friends': db.friends,
};

const _schemas = {
  'userProfiles': UserProfileSchema,
  'dailyLogs': DailyLogSchema,
  'habits': HabitSchema,
  'mealPlans': MealPlanSchema,
  'badges': BadgeSchema,
  'scannedMealLogs': ScannedMealLogSchema,
  'progressPhotos': ProgressPhotoSchema,
  'exerciseLogs': ExerciseLogSchema,
  'exercisePrs': ExercisePrSchema,
  'workoutPlans': WorkoutPlanSchema,
  'workoutSessions': WorkoutSessionSchema,
  'coachNotes': CoachNoteSchema,
  'bodyStats': BodyStatsSchema,
  'dailyMealLogs': DailyMealLogSchema,
  'habitCompletions': HabitCompletionSchema,
  'userFoodLogs': UserFoodLogSchema,
  'friends': FriendSchema,
};
const _identityFields = {
  'userProfiles': ['name'],
  'dailyLogs': ['date'],
  'habits': ['id', 'name'],
  'mealPlans': ['planName'],
  'badges': ['id'],
  'scannedMealLogs': ['id', 'date'],
  'progressPhotos': ['date', 'path'],
  'exerciseLogs': ['date', 'instanceId'],
  'exercisePrs': ['exerciseName'],
  'workoutPlans': ['planName'],
  'workoutSessions': ['key', 'jsonStr'],
  'coachNotes': ['date'],
  'bodyStats': ['date'],
  'dailyMealLogs': ['date'],
  'habitCompletions': ['date'],
  'userFoodLogs': ['normalizedName'],
  'friends': ['uid', 'name'],
};

// Limits are checked before decompression, decoding and extraction, not afterwards.
const _maxArchiveBytes = 256 * 1024 * 1024;
const _maxExpandedBytes = 512 * 1024 * 1024;
const _maxJsonBytes = 64 * 1024 * 1024;
const _maxPhotoBytes = 32 * 1024 * 1024;
const _maxArchiveFiles = 10000;

class _CreateRequest {
  final Map<String, Uint8List> snapshot;
  final String directory;
  final String? uid;
  final String? password;
  final bool includeMedia;
  _CreateRequest(
    this.snapshot,
    this.directory,
    this.uid,
    this.password,
    this.includeMedia,
  );
}

class _ReadRequest {
  final String path;
  final String? password;
  _ReadRequest(this.path, this.password);
}

class _DecodedBackup {
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> data;
  final Map<String, Uint8List> photos;
  final bool encrypted;
  final int totalEntries;
  final int missingMedia;
  _DecodedBackup(
    this.manifest,
    this.data,
    this.photos,
    this.encrypted,
    this.totalEntries,
    this.missingMedia,
  );
}

class _BackupFormatException implements Exception {
  final String message;
  final bool encrypted;
  _BackupFormatException(this.message, this.encrypted);
  @override
  String toString() => message;
}

Future<String> _createBackupArchive(_CreateRequest request) async {
  final staging = await Directory(
    request.directory,
  ).createTemp('backup_staging_');
  final destination = p.join(
    request.directory,
    'sthira_backup_${_scope(request.uid)}_${DateTime.now().microsecondsSinceEpoch}.zip',
  );
  try {
    final data = <String, dynamic>{
      for (final entry in request.snapshot.entries)
        entry.key: jsonDecode(utf8.decode(entry.value)),
    };
    final validated = _validateData(
      data,
      SchemaMigrationService.currentSchemaVersion,
    );
    final references = _mediaReferences(validated);
    final canonicalRoot = await Directory(
      request.directory,
    ).resolveSymbolicLinks();
    final media = <String, String>{};
    final files = <String, File>{};
    var missing = 0;
    var expanded = 0;
    final archivedPaths = <String, String>{};
    for (final reference in references) {
      if (!request.includeMedia) {
        missing++;
        continue;
      }
      final resolved = _resolveMediaReference(reference, request.directory);
      if (resolved == null) {
        missing++;
        continue;
      }
      final file = File(resolved);
      final absolute = p.normalize(p.absolute(resolved));
      if (!p.isWithin(p.normalize(p.absolute(request.directory)), absolute) ||
          !await file.exists()) {
        missing++;
        continue;
      }
      final canonical = await file.resolveSymbolicLinks();
      if (!p.isWithin(canonicalRoot, canonical)) {
        missing++;
        continue;
      }
      var entry = archivedPaths[canonical];
      if (entry == null) {
        final length = await file.length();
        if (length > _maxPhotoBytes)
          throw const FormatException(
            'A photo exceeds the 32 MB backup limit.',
          );
        expanded += length;
        if (expanded > _maxExpandedBytes)
          throw const FormatException('The backup is too large.');
        entry =
            'media/${sha256.convert(utf8.encode(canonical))}${p.extension(resolved).toLowerCase()}';
        archivedPaths[canonical] = entry;
        files[entry] = file;
      }
      media[reference.key] = entry;
    }
    final dataBytes = utf8.encode(jsonEncode(validated));
    if (dataBytes.length > _maxJsonBytes)
      throw const FormatException('The account data is too large to back up.');
    final manifest = <String, dynamic>{
      'schemaVersion': SchemaMigrationService.currentSchemaVersion,
      'appVersion': 'Sthira V1',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'totalEntries': validated.values.fold<int>(
        0,
        (sum, rows) => sum + (rows as List).length,
      ),
      'uid': request.uid,
      'media': media,
      'missingMedia': missing,
      'scope':
          'Account records and referenced local photos. Device preferences, credentials and caches excluded.',
    };
    final dataFile = await File(
      p.join(staging.path, 'data.json'),
    ).writeAsBytes(dataBytes);
    final manifestFile = await File(
      p.join(staging.path, 'manifest.json'),
    ).writeAsString(jsonEncode(manifest));
    final archivePath = p.join(staging.path, 'backup.zip');
    final encoder = ZipFileEncoder()..create(archivePath);
    try {
      await encoder.addFile(manifestFile, 'manifest.json');
      await encoder.addFile(dataFile, 'data.json');
      for (final entry in files.entries) {
        await encoder.addFile(entry.value, entry.key);
      }
    } finally {
      await encoder.close();
    }
    if (await File(archivePath).length() > _maxArchiveBytes)
      throw const FormatException('The backup exceeds 256 MB.');
    if (request.password?.isNotEmpty == true) {
      final bytes = await File(archivePath).readAsBytes();
      await File(destination).writeAsBytes(
        BackupEncryptionService.encryptBytes(bytes, request.password!),
        flush: true,
      );
    } else {
      await File(archivePath).copy(destination);
    }
    // Never advertise success for an empty, incomplete or unreadable archive.
    await _readBackupArchive(_ReadRequest(destination, request.password));
    return destination;
  } catch (_) {
    if (await File(destination).exists()) await File(destination).delete();
    rethrow;
  } finally {
    if (await staging.exists()) await staging.delete(recursive: true);
  }
}

Future<_DecodedBackup> _readBackupArchive(_ReadRequest request) async {
  var encrypted = false;
  try {
    final file = File(request.path);
    if (!await file.exists()) throw const FormatException('File not found.');
    if (await file.length() > _maxArchiveBytes)
      throw const FormatException('The backup exceeds 256 MB.');
    var bytes = await file.readAsBytes();
    final format = BackupEncryptionService.detectFormat(bytes);
    encrypted = format != BackupFormat.unencrypted;
    if (format == BackupFormat.unknownVersion)
      throw const FormatException('Unsupported backup format version.');
    if (encrypted) {
      if (request.password?.isNotEmpty != true)
        throw const FormatException('Password required.');
      try {
        bytes = format == BackupFormat.v2
            ? BackupEncryptionService.decryptV2(bytes, request.password!)
            : BackupEncryptionService.decryptV1(bytes, request.password!);
      } catch (_) {
        throw FormatException(
          format == BackupFormat.v1legacy
              ? 'Incorrect legacy password or corrupted file.'
              : 'Incorrect password or corrupted file.',
        );
      }
      if (format == BackupFormat.v1legacy &&
          (bytes.length < 4 ||
              bytes[0] != 80 ||
              bytes[1] != 75 ||
              bytes[2] != 3 ||
              bytes[3] != 4)) {
        throw const FormatException(
          'Incorrect legacy password or corrupted file.',
        );
      }
    }
    final zip = ZipDirectory()..read(InputMemoryStream(bytes));
    if (zip.fileHeaders.length > _maxArchiveFiles)
      throw const FormatException('Too many archive entries.');
    final names = <String>{};
    var expanded = 0;
    for (final header in zip.fileHeaders) {
      final file = header.file!;
      final name = file.filename;
      final segments = name.replaceAll('\\', '/').split('/');
      if (p.isAbsolute(name) ||
          name.contains(':') ||
          segments.contains('..') ||
          !names.add(name) ||
          ((header.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
        throw const FormatException('Unsafe or duplicate archive path.');
      }
      expanded += file.uncompressedSize;
      final limit = name == 'data.json'
          ? _maxJsonBytes
          : name == 'manifest.json'
          ? 4 * 1024 * 1024
          : _maxPhotoBytes;
      if (file.uncompressedSize > limit || expanded > _maxExpandedBytes) {
        throw const FormatException('Expanded backup is too large.');
      }
    }
    final contents = <String, Uint8List>{};
    for (final header in zip.fileHeaders) {
      final file = header.file!;
      if (file.filename.endsWith('/') || file.filename.endsWith('\\')) continue;
      final output = _BoundedOutput(file.uncompressedSize);
      file.decompress(output);
      final content = output.getBytes();
      if (content.length != file.uncompressedSize ||
          getCrc32(content) != file.crc32) {
        throw const FormatException('Corrupted archive entry.');
      }
      contents[file.filename] = content;
    }
    final manifestBytes = contents['manifest.json'];
    final dataBytes = contents['data.json'];
    if (manifestBytes == null || dataBytes == null)
      throw const FormatException('Missing manifest.json or data.json.');
    final manifest = jsonDecode(utf8.decode(manifestBytes));
    final raw = jsonDecode(utf8.decode(dataBytes));
    if (manifest is! Map<String, dynamic> ||
        raw is! Map<String, dynamic> ||
        manifest['schemaVersion'] is! int ||
        manifest['totalEntries'] is! int) {
      throw const FormatException('Invalid backup manifest or data.');
    }
    if (manifest['uid'] != null && manifest['uid'] is! String)
      throw const FormatException('Invalid account identity.');
    if (manifest['createdAt'] is! String ||
        DateTime.tryParse(manifest['createdAt'] as String) == null) {
      throw const FormatException('Invalid backup date.');
    }
    final data = _validateData(raw, manifest['schemaVersion'] as int);
    final count = data.values.fold<int>(
      0,
      (sum, rows) => sum + (rows as List).length,
    );
    if (manifest['totalEntries'] != count)
      throw const FormatException(
        'Backup record count does not match the manifest.',
      );
    final photos = <String, Uint8List>{
      for (final entry in contents.entries)
        if (_isPhotoPath(entry.key)) entry.key: entry.value,
    };
    final media = manifest['media'];
    if (media != null &&
        (media is! Map ||
            media.entries.any(
              (entry) =>
                  entry.key is! String ||
                  entry.value is! String ||
                  !photos.containsKey(entry.value),
            ))) {
      throw const FormatException('The photo manifest is incomplete.');
    }
    final missing = manifest['missingMedia'];
    if (missing != null && (missing is! int || missing < 0))
      throw const FormatException('Invalid missing-photo count.');
    return _DecodedBackup(
      manifest,
      data,
      photos,
      encrypted,
      count,
      missing as int? ?? 0,
    );
  } catch (error) {
    throw _BackupFormatException(
      error.toString().replaceFirst('FormatException: ', ''),
      encrypted,
    );
  }
}

Map<String, dynamic> _validateData(Map<String, dynamic> raw, int version) {
  final data = SchemaMigrationService.runMigrationsForRestore(raw, version);
  for (final entry in data.entries) {
    final schema = _schemas[entry.key]!;
    final ids = <dynamic>{};
    for (final dynamic value in entry.value as List) {
      final row = value as Map<String, dynamic>;
      for (final identity in _identityFields[entry.key]!) {
        if (row[identity] is! String)
          throw FormatException(
            'Missing or invalid $identity in ${entry.key}.',
          );
      }
      final id = row[schema.idName];
      if (id is! int || !ids.add(id))
        throw FormatException(
          'Missing or duplicate record ID in ${entry.key}.',
        );
      _validateProperties(row, schema.properties, schema.embeddedSchemas);
      for (final field in const [
        'isarCustomHabits',
        'isarCustomMealSlots',
        'isarCompletions',
        'isarOverrides',
        'isarStreaks',
        'jsonStr',
      ]) {
        if (!row.containsKey(field)) continue;
        final decoded = jsonDecode(row[field] as String);
        if (field == 'isarCustomHabits' || field == 'isarCustomMealSlots') {
          if (decoded is! List ||
              decoded.any((value) => value is! Map<String, dynamic>)) {
            throw FormatException('Invalid embedded data in $field.');
          }
        } else {
          if (decoded is! Map<String, dynamic> ||
              (field == 'isarOverrides' &&
                  decoded.values.any((value) => value is! String)) ||
              (field == 'isarStreaks' &&
                  decoded.values.any((value) => value is! int))) {
            throw FormatException('Invalid embedded data in $field.');
          }
        }
      }
    }
  }
  return data;
}

void _validateProperties(
  Map<String, dynamic> row,
  Map<String, PropertySchema> properties,
  Map<String, Schema<dynamic>> embedded,
) {
  for (final property in properties.values) {
    final value = row[property.name];
    if (value == null) continue;
    final kind = property.type.name;
    if (kind.endsWith('List')) {
      if (value is! List)
        throw FormatException('Invalid list ${property.name}.');
      for (final element in value) {
        if (element != null)
          _validateValue(
            element,
            kind.substring(0, kind.length - 4),
            property,
            embedded,
          );
      }
    } else {
      _validateValue(value, kind, property, embedded);
    }
  }
}

void _validateValue(
  dynamic value,
  String kind,
  PropertySchema property,
  Map<String, Schema<dynamic>> embedded,
) {
  final valid = switch (kind) {
    'bool' => value is bool,
    'byte' || 'int' || 'long' => value is int,
    'float' || 'double' => value is num && value.isFinite,
    'string' => value is String,
    'dateTime' =>
      value is int || (value is String && DateTime.tryParse(value) != null),
    'object' => value is Map<String, dynamic>,
    _ => false,
  };
  if (!valid) throw FormatException('Invalid value for ${property.name}.');
  if (kind == 'object') {
    final schema = embedded[property.target];
    if (schema != null)
      _validateProperties(
        value as Map<String, dynamic>,
        schema.properties,
        embedded,
      );
  }
}

bool _isPhotoPath(String path) => const [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
  '.heic',
  '.heif',
].contains(p.extension(path).toLowerCase());

class _MediaReference {
  final String collection;
  final String path;
  const _MediaReference(this.collection, this.path);
  String get key => '$collection::$path';
}

List<_MediaReference> _mediaReferences(Map<String, dynamic> collections) {
  final result = <String, _MediaReference>{};
  void visit(dynamic node, String collection) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (const ['path', 'photoPath', 'photoPaths'].contains(entry.key)) {
          final values = entry.value is List
              ? entry.value as List
              : [entry.value];
          for (final path in values) {
            if (path is String &&
                path.isNotEmpty &&
                !path.startsWith('http') &&
                !path.startsWith('assets/')) {
              final reference = _MediaReference(collection, path);
              result[reference.key] = reference;
            }
          }
        } else {
          visit(entry.value, collection);
        }
      }
    } else if (node is List) {
      for (final item in node) {
        visit(item, collection);
      }
    }
  }

  for (final entry in collections.entries) {
    visit(entry.value, entry.key);
  }
  return result.values.toList();
}

String? _resolveMediaReference(_MediaReference reference, String documents) {
  final normalized = reference.path.replaceAll('\\', '/');
  if (normalized.split('/').contains('..')) return null;
  final mediaFolder = reference.collection == 'scannedMealLogs'
      ? 'trufit_meal_photos'
      : 'trufit_media';
  if (p.isAbsolute(reference.path) ||
      p.windows.isAbsolute(reference.path) ||
      p.posix.isAbsolute(reference.path)) {
    // Rebase legacy absolute app-media paths when documents moved across devices.
    final marker = '$mediaFolder/';
    if (normalized.contains(marker))
      return p.join(documents, mediaFolder, normalized.split(marker).last);
    return reference.path;
  }
  if (normalized.startsWith('trufit_media/') ||
      normalized.startsWith('trufit_meal_photos/'))
    return p.join(documents, normalized);
  return p.join(documents, mediaFolder, normalized);
}

class _RestoreRequest {
  final _DecodedBackup backup;
  final String directory;
  final String accountRoot;
  _RestoreRequest(this.backup, this.directory, this.accountRoot);
}

class _PreparedRestore {
  final Map<String, Uint8List> data;
  final Map<String, int> counts;
  final int missingMedia;
  _PreparedRestore(this.data, this.counts, this.missingMedia);
}

Future<_PreparedRestore> _prepareRestore(_RestoreRequest request) async {
  final backup = request.backup;
  final manifestMedia = backup.manifest['media'] as Map?;
  final replacement = <String, String>{};
  var missing = 0;
  final written = <String>{};
  for (final reference in _mediaReferences(backup.data)) {
    // Read the new qualified manifest and earlier archives with raw-path keys.
    String? entry =
        (manifestMedia?[reference.key] ?? manifestMedia?[reference.path])
            as String?;
    if (manifestMedia == null) {
      final normalized = reference.path.replaceAll('\\', '/');
      final folder = reference.collection == 'scannedMealLogs'
          ? 'trufit_meal_photos'
          : 'trufit_media';
      final qualified = '$folder/$normalized';
      final matches = backup.photos.keys
          .where(
            (name) =>
                qualified == name ||
                normalized.endsWith('/$name') ||
                normalized == name,
          )
          .toList();
      if (matches.length == 1) entry = matches.single;
    }
    // References to one archived file retain one restored physical file.
    final identity = entry ?? reference.key;
    final target = p.join(
      request.directory,
      '${sha256.convert(utf8.encode(identity))}${p.extension(entry ?? reference.path).toLowerCase()}',
    );
    replacement[reference.key] = target;
    final bytes = backup.photos[entry];
    if (bytes == null) {
      final resolved = _resolveMediaReference(reference, request.accountRoot);
      if (resolved != null) {
        final original = File(resolved);
        final absolute = p.normalize(p.absolute(resolved));
        if (p.isWithin(
              p.normalize(p.absolute(request.accountRoot)),
              absolute,
            ) &&
            await original.exists() &&
            p.isWithin(
              await Directory(request.accountRoot).resolveSymbolicLinks(),
              await original.resolveSymbolicLinks(),
            )) {
          replacement[reference.key] = resolved;
          continue;
        }
      }
      missing++;
      continue;
    }
    if (written.add(target)) {
      await Directory(request.directory).create(recursive: true);
      await File(target).writeAsBytes(bytes, flush: true);
    }
  }
  dynamic rewrite(dynamic value, String collection, {bool isPath = false}) {
    if (value is String)
      return isPath ? replacement['$collection::$value'] ?? value : value;
    if (value is List)
      return value
          .map((item) => rewrite(item, collection, isPath: isPath))
          .toList();
    if (value is Map)
      return value.map(
        (key, val) => MapEntry(
          key,
          rewrite(
            val,
            collection,
            isPath: const ['path', 'photoPath', 'photoPaths'].contains(key),
          ),
        ),
      );
    return value;
  }

  final data = <String, Uint8List>{};
  final counts = <String, int>{};
  for (final entry in backup.data.entries) {
    data[entry.key] = Uint8List.fromList(
      utf8.encode(jsonEncode(rewrite(entry.value, entry.key))),
    );
    counts[entry.key] = (entry.value as List).length;
  }
  return _PreparedRestore(data, counts, missing);
}

/// Bound output even when a ZIP header lies about its expanded length.
class _BoundedOutput extends OutputMemoryStream {
  final int limit;
  _BoundedOutput(this.limit) : super(size: limit.clamp(1, 32768));
  void _check(int added) {
    if (length + added > limit)
      throw const FormatException('Archive entry exceeded its declared size.');
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }
}
