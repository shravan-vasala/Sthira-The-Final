import 'package:isar/isar.dart';
import '../models/coach_note.dart';
import '../interfaces/i_cloud_sync_service.dart';
import 'dart:convert';
import '../models/sync_queue_item.dart';

class CoachNoteRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
  }

  Stream<void> get watchUpdates => _isar.coachNotes.watchLazy();

  CoachNote? getNote(String date) {
    return _isar.coachNotes.where().dateEqualTo(date).findFirstSync();
  }

  Future<void> saveNote(CoachNote note) async {
    final database = _isar;
    final sync = _sync;
    await database.writeTxn(() async {
      final existing = await database.coachNotes
          .where()
          .dateEqualTo(note.date)
          .findFirst();
      if (existing != null) note.id = existing.id;
      await database.coachNotes.put(note);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'coach_notes',
            docId: note.date,
            payload: jsonEncode(note.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(database, _isar)) sync?.triggerFlush();
  }

  List<CoachNote> getRecentNotes(int limit, {String? throughDate}) {
    if (throughDate != null) {
      return _isar.coachNotes
          .filter()
          .dateLessThan(throughDate, include: true)
          .sortByDateDesc()
          .limit(limit)
          .findAllSync();
    }
    return _isar.coachNotes.where().sortByDateDesc().limit(limit).findAllSync();
  }

  // ── Cloud sync helpers ──

  Future<void> importNotesFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await database.writeTxn(() async {
      for (final entry in cloudData.entries) {
        final pending = await database.syncQueueItems
            .filter()
            .uidEqualTo(database.name)
            .collectionEqualTo('coach_notes')
            .docIdEqualTo(entry.key)
            .findFirst();
        // Unsynced local edits win. Otherwise the cloud snapshot is authoritative.
        if (pending != null) continue;
        final note = CoachNote.fromJson({...entry.value, 'date': entry.key});
        final existing = await database.coachNotes
            .where()
            .dateEqualTo(entry.key)
            .findFirst();
        if (existing != null) note.id = existing.id;
        await database.coachNotes.put(note);
      }
    });
  }

  Map<String, Map<String, dynamic>> exportNotesForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final notes = _isar.coachNotes.where().findAllSync();
    for (final note in notes) {
      result[note.date] = note.toJson();
    }
    return result;
  }
}
