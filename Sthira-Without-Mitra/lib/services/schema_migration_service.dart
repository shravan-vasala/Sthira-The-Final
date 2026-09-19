import 'package:isar/isar.dart';
import '../models/app_config.dart';

class SchemaMigrationService {
  static const int currentSchemaVersion =
      6; // Explicit nutrition completeness, timed sets and custom plan origin
  static const String _versionKey = 'schema_version';

  /// Run migrations for the active data on application startup.
  static Future<void> runStartupMigrations(Isar isar) async {
    final config = isar.appConfigs
        .where()
        .keyEqualTo(_versionKey)
        .findFirstSync();
    final int storedVersion = config != null
        ? int.tryParse(config.value) ?? 1
        : 1;

    if (storedVersion > currentSchemaVersion) {
      throw StateError('This database requires a newer version of Sthira.');
    }
    if (storedVersion == currentSchemaVersion) {
      return; // Already up to date
    }

    // Since we've fully migrated to Isar + Firebase Sync as the source of truth,
    // we bypass legacy local Hive migrations. Data is pulled from Firestore on sign-in.

    await isar.writeTxn(() async {
      await isar.appConfigs.put(
        AppConfig(key: _versionKey, value: currentSchemaVersion.toString()),
      );
    });

    // AiCache pruning has been extracted explicitly to AiCache.prune() running independently
  }

  static const collectionNames = [
    'userProfiles',
    'dailyLogs',
    'habits',
    'mealPlans',
    'badges',
    'scannedMealLogs',
    'progressPhotos',
    'exerciseLogs',
    'exercisePrs',
    'workoutPlans',
    'workoutSessions',
    'coachNotes',
    'bodyStats',
    'dailyMealLogs',
    'habitCompletions',
    'userFoodLogs',
    'friends',
  ];

  /// Run migrations for in-memory backup data before writing to storage during a restore.
  static Map<String, dynamic> runMigrationsForRestore(
    Map<String, dynamic> boxes,
    int manifestVersion,
  ) {
    // Versions before 4 used a different persistence format. Guessing at that
    // format can silently erase records, so require an export from a compatible app.
    if (manifestVersion < 4 || manifestVersion > currentSchemaVersion) {
      throw FormatException(
        'Unsupported backup schema $manifestVersion. '
        'Use a compatible Sthira version to export this backup again.',
      );
    }
    final required = collectionNames.where((name) => name != 'friends').toSet();
    final unknown = boxes.keys.toSet().difference(collectionNames.toSet());
    if (unknown.isNotEmpty || !boxes.keys.toSet().containsAll(required)) {
      throw const FormatException(
        'The backup is not a complete supported account snapshot.',
      );
    }
    if (manifestVersion >= 5 && !boxes.containsKey('friends')) {
      throw const FormatException('The backup is missing friends.');
    }
    final migrated = <String, dynamic>{};
    var total = 0;
    for (final name in collectionNames) {
      final rows =
          boxes[name] ?? <dynamic>[]; // Version 4 did not export Friends.
      if (rows is! List || rows.any((row) => row is! Map<String, dynamic>)) {
        throw FormatException('Invalid collection: $name.');
      }
      total += rows.length;
      if (total > 250000) {
        throw const FormatException('The backup contains too many records.');
      }
      migrated[name] = rows;
    }
    return migrated;
  }
}
