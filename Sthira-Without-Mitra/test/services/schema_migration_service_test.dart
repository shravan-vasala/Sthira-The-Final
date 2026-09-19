import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/schema_migration_service.dart';

void main() {
  test(
    'rejects unsupported legacy and future versions instead of guessing a destructive migration',
    () {
      for (final version in [0, 1, 2, 3, 999]) {
        expect(
          () => SchemaMigrationService.runMigrationsForRestore({}, version),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'complete native version 4 snapshot preserves profile and adds missing friends',
    () {
      final snapshot = <String, dynamic>{
        for (final collection in SchemaMigrationService.collectionNames)
          if (collection != 'friends') collection: <dynamic>[],
        'userProfiles': [
          {'id': 1, 'name': 'Old User', 'targetCalories': 2000},
        ],
      };
      final migrated = SchemaMigrationService.runMigrationsForRestore(
        snapshot,
        4,
      );
      expect(migrated['userProfiles'], snapshot['userProfiles']);
      expect(migrated['friends'], isEmpty);
      expect(
        snapshot.containsKey('friends'),
        isFalse,
        reason: 'Migration does not mutate its source.',
      );
    },
  );
  test(
    'missing or unknown collections cannot become a destructive restore',
    () {
      expect(
        () => SchemaMigrationService.runMigrationsForRestore({
          'dailyLogs': [],
        }, 5),
        throwsFormatException,
      );
      final snapshot = <String, dynamic>{
        for (final name in SchemaMigrationService.collectionNames) name: [],
      };
      snapshot['unknown'] = [];
      expect(
        () => SchemaMigrationService.runMigrationsForRestore(snapshot, 5),
        throwsFormatException,
      );
    },
  );
}
