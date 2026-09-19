import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/repositories/photo_meal_repository.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/models/scanned_meal_log.dart';
import '../helpers/test_isar_setup.dart';
import 'dart:typed_data';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock path provider to have consistent app directories during test
class MockPathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    test('Skipping Isar GUI linking tests on Linux CI', () {});
    return;
  }
  PathProviderPlatform.instance = MockPathProvider();

  late Isar isar;

  setUp(() async {
    isar = await setUpTestIsar();
  });

  tearDown(() async {
    await tearDownTestIsar(isar);
  });

  group('PhotoMealRepository Rules', () {
    test('init does not delete 31 day old logs', () async {
      final repo = PhotoMealRepository();
      
      // Inject historic 31-day old record
      final date = DateTime.now().subtract(const Duration(days: 31));
      
      await isar.writeTxn(() async {
        await isar.scannedMealLogs.put(ScannedMealLog(
          id: 'old_photo',
          date: date.toIso8601String().split('T')[0],
          photoPath: 'some_old_photo.jpg',
          mealType: 'Breakfast',
          foodName: 'Old Food',
          estimatedCalories: 500,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          portionMultiplier: 1,
          timestamp: date.toIso8601String(),
        ));
      });
      
      // 1 record exists before initialization
      expect(isar.scannedMealLogs.where().countSync(), 1);
      
      // Initialize repo, if cleanup runs it will be deleted
      await repo.init(isar);
      
      // Re-query database
      expect(isar.scannedMealLogs.where().countSync(), 1, reason: 'Historical record should not have been automatically deleted by init.');
    });
    
    test('getAbsolutePath throws ArgumentError on traversal inputs', () async {
       final repo = PhotoMealRepository();
       await repo.init(isar);
       
       expect(() => repo.getAbsolutePath('folder/../../system/etc/passwd'), throwsArgumentError);
       expect(() => repo.getAbsolutePath('../private_photo.jpg'), throwsArgumentError);
       expect(repo.getAbsolutePath('normal_photo.jpg'), isNot(contains('..')));
    });

    test('deleteScannedMeal cleans database row before deleting file', () async {
      final repo = PhotoMealRepository();
      await repo.init(isar);
      
      // Mocking a physical file
      final dummyFile = File('${Directory.systemTemp.path}/trufit_meal_photos/test_delete.jpg');
      await dummyFile.create(recursive: true);
      
      await isar.writeTxn(() async {
        await isar.scannedMealLogs.put(ScannedMealLog(
          id: 'test_delete_id',
          date: '2023-01-01',
          photoPath: 'test_delete.jpg',
          mealType: 'Breakfast',
          foodName: 'Test Food',
          estimatedCalories: 300,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          portionMultiplier: 1,
          timestamp: DateTime.now().toIso8601String(),
        ));
      });
      
      await repo.deleteScannedMeal('test_delete_id');
      
      expect(isar.scannedMealLogs.where().countSync(), 0);
      expect(await dummyFile.exists(), isFalse, reason: 'Physical file should be deleted AFTER database row is dropped');
    });
    
    test('saveScannedMeal rapidly generated names avoid collision via UUID', () async {
      final repo = PhotoMealRepository();
      await repo.init(isar);
      
      final srcFile = File('${Directory.systemTemp.path}/src.jpg');
      await srcFile.writeAsBytes([0]); // Dummy file content
      
      // Call twice rapidly to test UUID inclusion in file path and ID
      final p1 = repo.saveScannedMeal(
        date: '2023-01-01',
        sourcePhotoPath: srcFile.path,
        mealType: 'Breakfast',
        foodName: 'Food A',
        estimatedCalories: 100,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        portionMultiplier: 1,
      );
      
      final p2 = repo.saveScannedMeal(
        date: '2023-01-01',
        sourcePhotoPath: srcFile.path,
        mealType: 'Lunch',
        foodName: 'Food B',
        estimatedCalories: 100,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        portionMultiplier: 1,
      );
      
      final results = await Future.wait([p1, p2]);
      
      expect(results[0].photoPath != results[1].photoPath, isTrue, reason: 'UUID should ensure file paths are distinct');
      expect(results[0].id != results[1].id, isTrue);
    });
  });

  group('MediaRepository Rules', () {
    test('getAbsolutePath throws ArgumentError on traversal inputs', () async {
       final repo = MediaRepository();
       await repo.init(isar);
       
       expect(() => repo.getAbsolutePath('folder/../../system/etc/passwd'), throwsArgumentError);
       expect(() => repo.getAbsolutePath('../private_photo.jpg'), throwsArgumentError);
       expect(repo.getAbsolutePath('normal_photo.jpg'), isNot(contains('..')));
    });
    
    test('saveProgressPhoto rapid calls avoid collision', () async {
      final repo = MediaRepository();
      await repo.init(isar);
      
      final bytes = Uint8List.fromList([0]);
      final f1 = repo.saveProgressPhoto('2023-01-01', bytes);
      final f2 = repo.saveProgressPhoto('2023-01-01', bytes);
      
      final results = await Future.wait([f1, f2]);
      expect(results[0] != results[1], isTrue);
      
      final meta1 = repo.getProgressPhotoMeta('2023-01-01', results[0]);
      final meta2 = repo.getProgressPhotoMeta('2023-01-01', results[1]);
      
      expect(meta1.path, isNotNull);
      expect(meta2.path, isNotNull);
    });
  });
}
