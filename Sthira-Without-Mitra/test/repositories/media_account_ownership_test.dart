import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/scanned_meal_log.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/repositories/photo_meal_repository.dart';
import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar first;
  late Isar second;
  late Directory directory;
  setUp(() async {
    first = await setUpTestIsar();
    second = await setUpTestIsar();
    directory = await Directory.systemTemp.createTemp('media_ownership_');
  });
  tearDown(() async {
    await tearDownTestIsar(first);
    await tearDownTestIsar(second);
    await directory.delete(recursive: true);
  });
  test(
    'new photos have account-specific relative paths while legacy and restored paths resolve',
    () async {
      final repository = MediaRepository(
        documentsDirectory: () async => directory,
      );
      await repository.init(first);
      final path = await repository.saveProgressPhoto(
        '2026-09-19',
        Uint8List.fromList([1, 2, 3]),
      );
      final scope = base64Url
          .encode(utf8.encode(first.name))
          .replaceAll('=', '');
      expect(path, startsWith('accounts/$scope/progress_photos/'));
      expect(await File(repository.getAbsolutePath(path)).readAsBytes(), [
        1,
        2,
        3,
      ]);
      expect(
        repository.getAbsolutePath('progress_photos/legacy.jpg'),
        contains('trufit_media'),
      );
      final restored =
          '${directory.path}${Platform.pathSeparator}restored_media${Platform.pathSeparator}photo.jpg';
      expect(repository.getAbsolutePath(restored), restored);
      expect(
        repository.getAbsolutePath(r'C:\documents\restored_media\photo.jpg'),
        r'C:\documents\restored_media\photo.jpg',
      );
      expect(
        () => repository.getAbsolutePath('../outside.jpg'),
        throwsArgumentError,
      );
    },
  );
  test(
    'progress photo finishing after rebind writes neither account and removes its copied file',
    () async {
      final repository = MediaRepository(
        documentsDirectory: () async => directory,
      );
      await repository.init(first);
      final save = repository.saveProgressPhoto(
        '2026-09-19',
        Uint8List.fromList([1, 2, 3]),
      );
      final rejected = expectLater(save, throwsStateError);
      await repository.init(second);
      await rejected;
      expect(first.progressPhotos.countSync(), 0);
      expect(second.progressPhotos.countSync(), 0);
      expect(directory.listSync(recursive: true).whereType<File>(), isEmpty);
    },
  );
  test('scanned-meal photo copy cannot cross account rebinding', () async {
    final repository = PhotoMealRepository(
      documentsDirectory: () async => directory,
    );
    await repository.init(first);
    final source = await File(
      '${directory.path}/source.jpg',
    ).writeAsBytes([4, 5, 6]);
    final save = repository.saveScannedMeal(
      date: '2026-09-19',
      sourcePhotoPath: source.path,
      mealType: 'lunch',
      foodName: 'Dal',
      estimatedCalories: 200,
      proteinGrams: 10,
      carbsGrams: 20,
      fatGrams: 4,
      portionMultiplier: 1,
    );
    final rejected = expectLater(save, throwsStateError);
    await repository.init(second);
    await rejected;
    expect(first.scannedMealLogs.countSync(), 0);
    expect(second.scannedMealLogs.countSync(), 0);
    expect(
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => p.normalize(file.path)),
      [p.normalize(source.path)],
    );
  });
}
