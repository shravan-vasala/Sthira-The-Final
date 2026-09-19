import 'package:isar/isar.dart';

part 'ai_cache_entry.g.dart';

@collection
class AiCacheEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String cacheKey;
  final String cachedResponse;
  final DateTime timestamp;

  AiCacheEntry({
    required this.cacheKey,
    required this.cachedResponse,
    required this.timestamp,
  });
}
