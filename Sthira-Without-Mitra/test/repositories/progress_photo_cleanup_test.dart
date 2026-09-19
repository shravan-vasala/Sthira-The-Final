import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/scanned_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';

import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late Directory documents;
  late MediaRepository repository;

  setUp(() async {
    database = await setUpTestIsar();
    documents = await Directory.systemTemp.createTemp('progress_cleanup_');
    repository = MediaRepository(documentsDirectory: () async => documents);
    await repository.init(database);
  });

  tearDown(() async {
    await tearDownTestIsar(database);
    await documents.delete(recursive: true);
  });

  Future<File> restoredPhoto() async {
    final file = File(p.join(documents.path, 'restored_media', 'shared.jpg'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4]);
    await database.writeTxn(() async {
      await database.progressPhotos.put(
        ProgressPhoto(path: file.path, date: '2026-09-19', pose: 'front'),
      );
    });
    return file;
  }

  for (final reference in [
    'avatar',
    'meal photo',
    'meal gallery',
    'scanned meal',
  ]) {
    test(
      'deleting restored physique photo retains shared $reference bytes',
      () async {
        final file = await restoredPhoto();
        await database.writeTxn(() async {
          switch (reference) {
            case 'avatar':
              await database.userProfiles.put(
                UserProfile(photoPath: file.path),
              );
            case 'meal photo':
            case 'meal gallery':
              await database.dailyMealLogs.put(
                DailyMealLog(
                  date: '2026-09-19',
                  customSlots: {
                    'lunch': MealSlotLog(
                      photoPath: reference == 'meal photo' ? file.path : null,
                      photoPaths: reference == 'meal gallery'
                          ? [file.path]
                          : [],
                      totalCalories: 200,
                    ),
                  },
                ),
              );
            case 'scanned meal':
              await database.scannedMealLogs.put(_scan(file.path));
          }
        });

        await repository.deletePhoto('2026-09-19', file.path);

        expect(database.progressPhotos.countSync(), 0);
        expect(await file.readAsBytes(), [1, 2, 3, 4]);
        switch (reference) {
          case 'avatar':
            expect(
              database.userProfiles.where().findFirstSync()!.photoPath,
              file.path,
            );
          case 'meal photo':
          case 'meal gallery':
            final slot = database.dailyMealLogs
                .where()
                .findFirstSync()!
                .customSlots['lunch']!;
            expect(
              reference == 'meal photo'
                  ? slot.photoPath
                  : slot.photoPaths.single,
              file.path,
            );
          case 'scanned meal':
            expect(
              database.scannedMealLogs.where().findFirstSync()!.photoPath,
              file.path,
            );
        }
      },
    );
  }

  test(
    'relative and absolute progress references keep a file until the last deletion',
    () async {
      final path = await repository.saveProgressPhoto(
        '2026-09-19',
        Uint8List.fromList([7, 8, 9]),
      );
      final file = File(repository.getAbsolutePath(path));
      await database.writeTxn(() async {
        await database.progressPhotos.put(
          ProgressPhoto(path: file.path, date: '2026-09-18', pose: 'side'),
        );
      });

      await repository.deletePhoto('2026-09-19', path);
      expect(database.progressPhotos.countSync(), 1);
      expect(await file.readAsBytes(), [7, 8, 9]);

      await repository.deletePhoto('2026-09-18', file.path);
      expect(database.progressPhotos.countSync(), 0);
      expect(await file.exists(), isFalse);
    },
  );

  test(
    'relative scanned-meal references resolve in their own media directory',
    () async {
      final file = File(
        p.join(documents.path, 'trufit_meal_photos', 'scan.jpg'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes([5, 6]);
      await database.writeTxn(() async {
        await database.progressPhotos.put(
          ProgressPhoto(path: file.path, date: '2026-09-19', pose: 'front'),
        );
        await database.scannedMealLogs.put(_scan('scan.jpg'));
      });

      await repository.deletePhoto('2026-09-19', file.path);

      expect(database.progressPhotos.countSync(), 0);
      expect(await file.readAsBytes(), [5, 6]);
    },
  );

  test(
    'same relative name in a different media directory does not prevent cleanup',
    () async {
      final photo = File(repository.getAbsolutePath('same.jpg'));
      final scan = File(
        p.join(documents.path, 'trufit_meal_photos', 'same.jpg'),
      );
      await photo.writeAsBytes([1, 2]);
      await scan.parent.create(recursive: true);
      await scan.writeAsBytes([3, 4]);
      await database.writeTxn(() async {
        await database.progressPhotos.put(
          ProgressPhoto(path: 'same.jpg', date: '2026-09-19', pose: 'front'),
        );
        await database.scannedMealLogs.put(_scan('same.jpg'));
      });

      await repository.deletePhoto('2026-09-19', 'same.jpg');

      expect(database.progressPhotos.countSync(), 0);
      expect(await photo.exists(), isFalse);
      expect(await scan.readAsBytes(), [3, 4]);
    },
  );

  test('wrong date cannot remove metadata or the backing file', () async {
    final file = await restoredPhoto();

    await repository.deletePhoto('2026-09-18', file.path);

    expect(database.progressPhotos.countSync(), 1);
    expect(await file.readAsBytes(), [1, 2, 3, 4]);
  });

  test(
    'account rebind rejects pending deletion before removing metadata or bytes',
    () async {
      final file = await restoredPhoto();
      final other = await setUpTestIsar();
      try {
        final deletion = repository.deletePhoto('2026-09-19', file.path);
        final rejected = expectLater(deletion, throwsStateError);
        await repository.init(other);
        await rejected;

        expect(database.progressPhotos.countSync(), 1);
        expect(other.progressPhotos.countSync(), 0);
        expect(await file.readAsBytes(), [1, 2, 3, 4]);
      } finally {
        await tearDownTestIsar(other);
      }
    },
  );
}

ScannedMealLog _scan(String path) => ScannedMealLog(
  id: 'scan',
  date: '2026-09-19',
  photoPath: path,
  mealType: 'lunch',
  foodName: 'Dal',
  estimatedCalories: 200,
  proteinGrams: 10,
  carbsGrams: 20,
  fatGrams: 4,
  portionMultiplier: 1,
  timestamp: '2026-09-19T12:00:00Z',
);
