import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionLookupService', () {
    late NutritionLookupService service;

    setUp(() async {
      service = NutritionLookupService();
      // Since it's a test, we mock the asset loading or just load from disk.
      // But Flutter test environment doesn't always have access to assets easily unless configured.
      // However, for this test we can just call load() and if it fails to load the real asset,
      // we could mock it. Actually, `TestWidgetsFlutterBinding` allows loading assets if they are in pubspec.
      await service.load();
    });

    test('match returns item for exact name match', () {
      final match = service.match('White Rice');
      expect(match, isNotNull);
      expect(match!.id, 'white_rice');
    });

    test('match returns item for alias match (Telugu names)', () {
      final match1 = service.match('annam');
      expect(match1, isNotNull);
      expect(match1!.id, 'white_rice');

      final match2 = service.match('kodi kura');
      expect(match2, isNotNull);
      expect(match2!.id, 'chicken_curry');
    });

    test('match returns item for partial match with weird casing/spaces', () {
      final match = service.match('  Kodi   Vepudu  ');
      expect(match, isNotNull);
      expect(match!.id, 'chicken_fry');
    });

    test('match returns null for unknown dish', () {
      final match = service.match('Some random alien food');
      expect(match, isNull);
    });
  });
}
