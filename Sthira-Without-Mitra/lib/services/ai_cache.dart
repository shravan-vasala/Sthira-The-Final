import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import '../models/ai_cache_entry.dart';

class AiCache {
  final Isar? _database;
  final Isar? Function()? _databaseResolver;
  final Duration defaultTtl = const Duration(hours: 24);

  AiCache({Isar? database, Isar? Function()? databaseResolver})
    : _database = database,
      _databaseResolver = databaseResolver;

  Isar? get _openDatabase {
    try {
      // A supplied resolver returning null means this account is unavailable.
      // Never fall back to another user's open database in that case.
      final database = _databaseResolver != null
          ? _databaseResolver()
          : _database ??
                (Isar.instanceNames.length == 1
                    ? Isar.getInstance(Isar.instanceNames.single)
                    : null);
      return database != null && database.isOpen ? database : null;
    } catch (_) {
      return null;
    }
  }

  /// Pins one analysis to the account that started it, including deferred writes.
  AiCache forRequest() {
    final database = _openDatabase;
    return AiCache(databaseResolver: () => database);
  }

  String _hash(
    String prompt,
    String? systemInstruction,
    String? imageContext,
    String? schemaStr,
  ) {
    var raw = prompt;
    if (systemInstruction != null) {
      raw += systemInstruction;
    }
    if (imageContext != null) {
      raw += imageContext;
    }
    if (schemaStr != null) {
      raw += schemaStr;
    }
    return 'ai_cache_${sha256.convert(utf8.encode(raw)).toString()}';
  }

  Map<String, dynamic>? get(
    String prompt,
    String? systemInstruction, [
    String? imageContext,
    String? schemaStr,
  ]) {
    final database = _openDatabase;
    if (database == null) return null;
    try {
      final key = _hash(prompt, systemInstruction, imageContext, schemaStr);
      final entry = database.aiCacheEntrys
          .where()
          .cacheKeyEqualTo(key)
          .findFirstSync();
      if (entry == null ||
          DateTime.now().difference(entry.timestamp) > defaultTtl) {
        return null;
      }
      return jsonDecode(entry.cachedResponse) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    // Expiry/corruption is a miss, not a synchronous write transaction. Cleanup
    // happens separately so a meal save cannot make cache lookup fail or wait.
  }

  Future<void> set(
    String prompt,
    String? systemInstruction,
    Map<String, dynamic> result, [
    String? imageContext,
    String? schemaStr,
  ]) async {
    final database = _openDatabase;
    if (database == null) return;
    final key = _hash(prompt, systemInstruction, imageContext, schemaStr);
    final data = jsonEncode(result);

    final existing = database.aiCacheEntrys
        .where()
        .cacheKeyEqualTo(key)
        .findFirstSync();

    final entry = AiCacheEntry(
      cacheKey: key,
      cachedResponse: data,
      timestamp: DateTime.now(),
    );

    if (existing != null) {
      entry.id = existing.id;
    }

    await database.writeTxn(() async {
      await database.aiCacheEntrys.put(entry);
    });
  }

  /// Extracts routine bounded cache cleanup out of one-time schema version migrations.
  /// Runs reliably uncoupled from startup schema blocks.
  Future<void> prune() async {
    final database = _openDatabase;
    if (database == null) return;
    try {
      final cutoff = DateTime.now().subtract(defaultTtl);
      await database.writeTxn(() async {
        final oldEntries = database.aiCacheEntrys
            .where()
            .filter()
            .timestampLessThan(cutoff)
            .findAllSync();
        if (oldEntries.isNotEmpty) {
          await database.aiCacheEntrys.deleteAll(
            oldEntries.map((e) => e.id).toList(),
          );
        }
      });
    } catch (_) {
      // Ignore background cache pruning failures safely
    }
  }
}
