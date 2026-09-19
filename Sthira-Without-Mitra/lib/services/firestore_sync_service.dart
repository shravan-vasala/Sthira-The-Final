import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../interfaces/i_auth_service.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/sync_queue_item.dart';
import 'cloud_sync_transport.dart';
import 'cloud_record_store.dart';

/// A durable, account-bound outbox. Local writes remain usable without a network.
class FirestoreSyncService implements ICloudSyncService {
  FirestoreSyncService(
    this._auth, {
    Isar? Function()? databaseResolver,
    CloudSyncTransport? transport,
    Stream<List<ConnectivityResult>>? connectivity,
    bool startPaused = false,
    this.requestTimeout = const Duration(seconds: 20),
    this.drainTimeout = const Duration(seconds: 5),
  }) : _databaseResolver = databaseResolver,
       _transport = transport ?? FirestoreTransport(),
       _isSyncPaused = startPaused {
    _connectivity = (connectivity ?? Connectivity().onConnectivityChanged)
        .listen((results) {
          if (!results.contains(ConnectivityResult.none)) triggerFlush();
        });
    if (!startPaused) triggerFlush();
  }
  final IAuthService _auth;
  final Isar? Function()? _databaseResolver;
  final CloudSyncTransport _transport;
  final Duration requestTimeout;
  final Duration drainTimeout;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  final Set<Future<void>> _pendingCommits = {};
  Timer? _flushTimer;
  Future<void>? _flushing;
  bool _isSyncPaused;
  bool _disposed = false;
  int _generation = 0;
  int _consecutiveFailures = 0;
  String? lastError;

  Isar? get _database {
    final database = _databaseResolver != null
        ? _databaseResolver()
        : Isar.getInstance(_auth.uid ?? 'guest');
    return database != null && database.isOpen ? database : null;
  }

  @override
  bool get canSync =>
      !_disposed &&
      _auth.isSignedIn &&
      _auth.uid != null &&
      _database?.name == _auth.uid;
  @override
  String? get currentUid => _auth.uid;
  bool _owns(Isar database, String uid, int generation) =>
      !_disposed &&
      !_isSyncPaused &&
      generation == _generation &&
      _auth.uid == uid &&
      identical(_database, database) &&
      database.isOpen;

  @override
  Stream<int> get pendingCountStream {
    final database = _database;
    final uid = currentUid;
    if (database == null || uid == null || database.name != uid)
      return Stream.value(0);
    return database.syncQueueItems
        .watchLazy(fireImmediately: true)
        .asyncMap(
          (_) => database.syncQueueItems
              .where()
              .uidEqualToAnyTimestamp(uid)
              .count(),
        );
  }

  @override
  void pauseSync() {
    _isSyncPaused = true;
    _generation++;
    _flushTimer?.cancel();
  }

  @override
  Future<void> pauseAndDrainSync() async {
    pauseSync();
    final active = _flushing;
    if (active != null) await active.timeout(drainTimeout);
    // A timeout stops waiting, not an SDK write. Never restore over an unsettled write.
    if (_pendingCommits.isNotEmpty)
      await Future.wait(_pendingCommits.toList()).timeout(drainTimeout);
  }

  @override
  void resumeSync() {
    if (_disposed) return;
    _isSyncPaused = false;
    triggerFlush();
  }

  @override
  void triggerFlush() {
    if (_disposed || _isSyncPaused || !canSync) return;
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(flushQueue());
    });
  }

  @override
  Future<void> flushNow() async {
    final database = _database;
    final uid = currentUid;
    if (database == null || uid == null || !canSync) return;
    // Manual retry can retry denied writes after permissions/connectivity recover.
    await database.writeTxn(() async {
      final failed = await database.syncQueueItems
          .where()
          .uidEqualToAnyTimestamp(uid)
          .filter()
          .quarantinedEqualTo(true)
          .findAll();
      for (final item in failed) {
        if (item.lastError == 'Invalid queued data') continue;
        item.quarantined = false;
        await database.syncQueueItems.put(item);
      }
    });
    await flushQueue();
    if (lastError != null) throw StateError(lastError!);
  }

  SyncQueueItem _item(
    Isar database,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) => SyncQueueItem(
    collection: collection,
    docId: docId,
    payload: jsonEncode(data),
    timestamp: DateTime.now(),
    uid: database.name,
  );
  @override
  void queueSyncInTxn(
    Isar isar,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    if (isar.name == 'guest') return;
    isar.syncQueueItems.putSync(_item(isar, collection, docId, data));
  }

  @override
  void queueDeleteInTxn(Isar isar, String collection, String docId) =>
      queueSyncInTxn(isar, '_delete_/$collection', docId, {});
  @override
  void queueProfileInTxn(Isar isar, Map<String, dynamic> data) =>
      queueSyncInTxn(isar, '_profile_', 'profile', data);
  @override
  void syncToCloud(String collection, String docId, Map<String, dynamic> data) {
    final database = _database;
    if (database == null || !canSync) return;
    database.writeTxnSync(
      () => queueSyncInTxn(database, collection, docId, data),
    );
    triggerFlush();
  }

  @override
  void deleteFromCloud(String collection, String docId) =>
      syncToCloud('_delete_/$collection', docId, {});
  @override
  void syncProfile(Map<String, dynamic> data) =>
      syncToCloud('_profile_', 'profile', data);
  @override
  Future<void> pushProfileNow(Map<String, dynamic> data) async {
    syncProfile(data);
    await flushNow();
  }

  Future<void> _commit(String uid, List<CloudWrite> writes) async {
    final pending = _transport.commit(uid, writes);
    _pendingCommits.add(pending);
    // Keep tracking the actual SDK future if our wait times out.
    unawaited(
      pending.then<void>(
        (_) {
          _pendingCommits.remove(pending);
          triggerFlush();
        },
        onError: (Object _, StackTrace __) {
          _pendingCommits.remove(pending);
          triggerFlush();
        },
      ),
    );
    await pending.timeout(requestTimeout);
  }

  Future<void> flushQueue() {
    if (_flushing != null) return _flushing!;
    if (!canSync || _isSyncPaused || _pendingCommits.isNotEmpty)
      return Future.value();
    final future = _flushPass();
    _flushing = future;
    return future.whenComplete(() {
      if (identical(_flushing, future)) _flushing = null;
    });
  }

  String _target(SyncQueueItem item) =>
      '${item.collection.replaceFirst('_delete_/', '')}/${item.docId}';
  int _compareIntent(SyncQueueItem a, SyncQueueItem b) {
    final time = a.timestamp.compareTo(b.timestamp);
    return time == 0 ? a.id.compareTo(b.id) : time;
  }

  Future<void> _acknowledge(
    Isar database,
    String uid,
    List<SyncQueueItem> acknowledged,
  ) async {
    await database.writeTxn(() async {
      for (final item in acknowledged) {
        final versions = await database.syncQueueItems
            .where()
            .docIdEqualTo(item.docId)
            .filter()
            .uidEqualTo(uid)
            .findAll();
        await database.syncQueueItems.deleteAll(
          versions
              .where(
                (candidate) =>
                    _target(candidate) == _target(item) &&
                    _compareIntent(candidate, item) <= 0,
              )
              .map((candidate) => candidate.id)
              .toList(),
        );
        if (item.collection != '_reconcile_') {
          await CloudRecordStore.rememberVersion(
            database,
            item.collection.replaceFirst('_delete_/', ''),
            item.docId,
            item.timestamp,
            deleted: item.collection.startsWith('_delete_/'),
          );
        }
      }
    });
  }

  bool _permanent(Object error) =>
      error is FirebaseException &&
      const {
        'permission-denied',
        'invalid-argument',
        'unauthenticated',
        'failed-precondition',
      }.contains(error.code);
  Future<void> _markFailure(
    Isar database,
    Iterable<SyncQueueItem> items,
    Object error, {
    bool invalid = false,
  }) async {
    if (!database.isOpen) return;
    await database.writeTxn(() async {
      for (final item in items) {
        final current = await database.syncQueueItems.get(item.id);
        if (current == null) continue;
        current.attempts++;
        current.quarantined = invalid || _permanent(error);
        current.lastError = invalid
            ? 'Invalid queued data'
            : (_permanent(error)
                  ? 'Cloud permission or data validation failed'
                  : 'Cloud sync is temporarily unavailable');
        await database.syncQueueItems.put(current);
      }
    });
  }

  Future<void> _flushPass() async {
    final database = _database;
    final uid = currentUid;
    final generation = _generation;
    if (database == null || uid == null) return;
    lastError = null;
    try {
      // Limit each pass. More pages are scheduled only after measurable progress.
      final items = await database.syncQueueItems
          .where()
          .uidEqualToAnyTimestamp(uid)
          .filter()
          .quarantinedEqualTo(false)
          .sortByTimestamp()
          .limit(2000)
          .findAll();
      // Isar 3's native sort builder does not resolve the special ID field,
      // despite generating thenById(). Break timestamp ties in this bounded page.
      items.sort(_compareIntent);
      if (!_owns(database, uid, generation)) return;
      final folded = <String, SyncQueueItem>{};
      for (final item in items) {
        folded[_target(item)] = item;
      }
      // Work on at most one commit batch of distinct targets per pass.
      final candidates = Map<String, SyncQueueItem>.fromEntries(
        folded.entries.take(400),
      );
      var pruned = false;
      // A later quarantined or newly queued value still supersedes an older edit.
      // Resolve each target beyond the bounded page, so old poison rows cannot
      // starve new edits and an old value is never uploaded over newer intent.
      for (final key in candidates.keys.toList()) {
        final target = candidates[key]!;
        final versions =
            (await database.syncQueueItems
                    .where()
                    .docIdEqualTo(target.docId)
                    .filter()
                    .uidEqualTo(uid)
                    .findAll())
                .where((item) => _target(item) == key)
                .toList()
              ..sort(_compareIntent);
        if (versions.isEmpty) {
          candidates.remove(key);
          continue;
        }
        final newest = versions.last;
        candidates[key] = newest;
        if (newest.quarantined && versions.length > 1) {
          await database.writeTxn(() async {
            await database.syncQueueItems.deleteAll(
              versions
                  .take(versions.length - 1)
                  .map((item) => item.id)
                  .toList(),
            );
          });
          pruned = true;
        }
      }
      final pending =
          candidates.values.where((item) => !item.quarantined).toList()
            ..sort((a, b) {
              if ((a.collection == '_reconcile_') !=
                  (b.collection == '_reconcile_'))
                return a.collection == '_reconcile_' ? 1 : -1;
              return _compareIntent(a, b);
            });
      if (pending.isEmpty) {
        final remaining = await database.syncQueueItems
            .where()
            .uidEqualToAnyTimestamp(uid)
            .count();
        if (remaining > 0)
          lastError = 'Some edits need attention before they can sync.';
        if (pruned) triggerFlush();
        return;
      }
      final writes = <CloudWrite>[];
      final included = <SyncQueueItem>[];
      for (final item in pending.take(400)) {
        try {
          if (item.collection == '_reconcile_') {
            if (writes.isNotEmpty) break;
            final ordinary = await database.syncQueueItems
                .where()
                .uidEqualToAnyTimestamp(uid)
                .filter()
                .not()
                .collectionEqualTo('_reconcile_')
                .count();
            if (ordinary > 0) {
              lastError =
                  'Restored edits must finish uploading before cloud cleanup.';
              return;
            }
            try {
              final map = jsonDecode(item.payload) as Map<String, dynamic>;
              final keep = (map['ids'] as List).cast<String>().toSet();
              if (item.docId.isEmpty ||
                  item.docId.contains('/') ||
                  item.docId.startsWith('_')) {
                throw const FormatException('Invalid queued data');
              }
              final remote = await _transport
                  .readCollection(uid, item.docId)
                  .timeout(requestTimeout);
              if (!_owns(database, uid, generation)) return;
              final later = await database.syncQueueItems
                  .where()
                  .uidEqualToAnyTimestamp(uid)
                  .filter()
                  .collectionEqualTo(item.docId)
                  .findAll();
              keep.addAll(later.map((entry) => entry.docId));
              final obsolete = remote.keys
                  .where((id) => !keep.contains(id))
                  .toList();
              for (var i = 0; i < obsolete.length; i += 400) {
                if (!_owns(database, uid, generation)) return;
                await _commit(
                  uid,
                  obsolete
                      .skip(i)
                      .take(400)
                      .map((id) => CloudWrite(item.docId, id, {}, delete: true))
                      .toList(),
                );
              }
              if (!_owns(database, uid, generation)) return;
              if (obsolete.isNotEmpty) {
                await database.writeTxn(() async {
                  for (final id in obsolete) {
                    await CloudRecordStore.rememberVersion(
                      database, item.docId, id, item.timestamp, deleted: true,
                    );
                  }
                });
              }
              await _acknowledge(database, uid, [item]);
              triggerFlush();
              return;
            } catch (error) {
              await _markFailure(
                database,
                [item],
                error,
                invalid: error is FormatException || error is TypeError,
              );
              rethrow;
            }
          }
          final data = jsonDecode(item.payload);
          if (data is! Map<String, dynamic> ||
              item.docId.isEmpty ||
              item.docId.contains('/') ||
              item.collection.replaceFirst('_delete_/', '').contains('/')) {
            throw const FormatException('Invalid queued data');
          }
          writes.add(
            CloudWrite(
              item.collection.replaceFirst('_delete_/', ''),
              item.docId,
              {
                ...data,
                '_syncUpdatedAt': item.timestamp.toUtc().toIso8601String(),
              },
              delete: item.collection.startsWith('_delete_/'),
            ),
          );
          included.add(item);
        } on FormatException catch (error) {
          await _markFailure(database, [item], error, invalid: true);
          pruned = true;
          lastError = 'Some edits contain invalid data and need attention.';
        } on TypeError catch (error) {
          await _markFailure(database, [item], error, invalid: true);
          pruned = true;
          lastError = 'Some edits contain invalid data and need attention.';
        }
      }
      if (!_owns(database, uid, generation)) return;
      if (writes.isEmpty) {
        if (pruned) triggerFlush();
        return;
      }
      try {
        await _commit(uid, writes);
      } catch (error) {
        await _markFailure(database, included, error);
        rethrow;
      }
      if (!_owns(database, uid, generation)) return;
      await _acknowledge(database, uid, included);
      _consecutiveFailures = 0;
      if (await database.syncQueueItems
          .where()
          .uidEqualToAnyTimestamp(uid)
          .filter()
          .quarantinedEqualTo(false)
          .isNotEmpty())
        triggerFlush();
    } catch (error) {
      lastError = _permanent(error)
          ? 'Cloud access was denied. Your edits remain on this device.'
          : 'Cloud sync is unavailable. Your edits remain on this device.';
      if (!_disposed &&
          !_isSyncPaused &&
          generation == _generation &&
          !_permanent(error)) {
        _consecutiveFailures = (_consecutiveFailures + 1).clamp(1, 6);
        _flushTimer?.cancel();
        _flushTimer = Timer(
          Duration(seconds: 5 * (1 << (_consecutiveFailures - 1))),
          () {
            unawaited(flushQueue());
          },
        );
      }
      debugPrint('FirestoreSync: $lastError (${error.runtimeType})');
      if (error is IsarError || error is UnsupportedError || error is ArgumentError) {
        debugPrint('FirestoreSync local operation failed: $error');
      }
    }
  }

  void _checkReadScope(Isar? database, String uid) {
    if (_disposed || _auth.uid != uid || !identical(_database, database))
      throw StateError('Account changed during cloud sync.');
  }

  @override
  Future<Map<String, Map<String, dynamic>>> pullCollection(
    String collection,
  ) async {
    if (!canSync) return {};
    final database = _database;
    final uid = currentUid!;
    final result = await _transport
        .readCollection(uid, collection)
        .timeout(requestTimeout);
    _checkReadScope(database, uid);
    return result;
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> streamCollection(
    String collection,
  ) {
    if (!canSync) return const Stream.empty();
    final database = _database;
    final uid = currentUid!;
    final generation = _generation;
    return _transport
        .watchCollection(uid, collection)
        .where((_) => _owns(database!, uid, generation));
  }

  @override
  Future<Map<String, Map<String, dynamic>>> pullGlobalCollection(
    String collection,
  ) => _transport.readGlobal(collection).timeout(requestTimeout);
  @override
  Future<Map<String, dynamic>?> pullProfile() async {
    if (!canSync) return null;
    final database = _database;
    final uid = currentUid!;
    final result = await _transport.readProfile(uid).timeout(requestTimeout);
    _checkReadScope(database, uid);
    return result;
  }

  Stream<Map<String, dynamic>?> streamProfile() {
    if (!canSync) return const Stream.empty();
    final database = _database!;
    final uid = currentUid!;
    final generation = _generation;
    return _transport
        .watchProfile(uid)
        .where((_) => _owns(database, uid, generation));
  }

  @override
  Future<bool> hasCloudData() async => await pullProfile() != null;
  @override
  Future<void> bulkSync(
    String collection,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    final database = _database;
    if (database == null || database.name == 'guest') return;
    await database.writeTxn(() async {
      for (final entry in docs.entries) {
        await database.syncQueueItems.put(
          _item(database, collection, entry.key, entry.value),
        );
      }
    });
    triggerFlush();
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _flushTimer?.cancel();
    await _connectivity?.cancel();
  }
}
