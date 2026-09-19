import '../services/cloud_record_store.dart';
import 'package:isar/isar.dart';
import '../models/body_stats.dart';
import '../interfaces/i_cloud_sync_service.dart';
import 'dart:convert';
import '../models/sync_queue_item.dart';

class BodyStatsRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
  }

  BodyStats? getStats(String date) {
    return _isar.bodyStats.where().dateEqualTo(date).findFirstSync();
  }

  Future<void> saveStats(BodyStats stats) async {
    if (!const {'cm', 'inches'}.contains(stats.unit) ||
        stats.allMeasurements.values.any(
          (value) => value != null && (!value.isFinite || value <= 0),
        )) {
      throw ArgumentError('Use positive measurements in cm or inches.');
    }
    final database = _isar;
    final sync = _sync;
    final existing = getStats(stats.date);
    if (existing != null) {
      stats.id = existing.id;
    }
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.bodyStats.put(stats);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'body_stats',
            docId: stats.date,
            payload: jsonEncode(stats.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  BodyStats? getLatestStats() {
    return _isar.bodyStats.where().sortByDateDesc().findFirstSync();
  }

  List<BodyStats> getAllStats() {
    return _isar.bodyStats.where().sortByDate().findAllSync();
  }

  // ── Cloud sync helpers ──

  Future<void> importStatsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'body_stats',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Map<String, Map<String, dynamic>> exportStatsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final allStats = getAllStats();
    for (final stats in allStats) {
      result[stats.date] = stats.toJson();
    }
    return result;
  }
}
