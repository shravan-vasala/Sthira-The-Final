import 'package:isar/isar.dart';

part 'food_search_cache.g.dart';

@collection
class FoodSearchCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String normalizedQuery;
  final String cachedResponseJson;
  final DateTime timestamp;
  final String schemaVersion;

  FoodSearchCache({
    required this.normalizedQuery,
    required this.cachedResponseJson,
    required this.timestamp,
    required this.schemaVersion,
  });
}
