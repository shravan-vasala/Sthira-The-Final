import '../services/firestore_sync_service.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../providers/app_providers.dart';
import '../models/app_config.dart';
import '../models/sync_queue_item.dart';
import '../models/user_profile.dart';
import '../models/progress_photo.dart';
import '../models/scanned_meal_log.dart';
import '../models/user_food_log.dart';
import '../services/app_database_manager.dart';
import '../services/cloud_record_store.dart';
import '../services/schema_migration_service.dart';
import 'reminders_provider.dart';

final accountSessionProvider = Provider<AccountSession>((ref) {
  final session = AccountSession(ref);
  ref.onDispose(session.dispose);
  return session;
});
final accountSessionErrorProvider = StateProvider<String?>((ref) => null);

/// Serializes account changes and restore. Repositories never resolve an account
/// from Firebase halfway through an operation; they receive the bound database.
class AccountSession {
  AccountSession(this.ref);
  final Ref ref;
  Future<void> _tail = Future.value();
  final List<StreamSubscription> _incoming = [];
  StreamSubscription? _authSubscription;
  StreamSubscription? _queueSubscription;
  bool _disposed = false;
  bool _manualAuth = false;
  bool _restoring = false;
  bool _reattaching = false;
  String? _hydratedAccount;
  Future<void> _serialize(Future<void> Function() operation) {
    final task = _tail.then((_) => operation());
    _tail = task.catchError((Object _) {});
    return task;
  }

  void start() {
    _authSubscription ??= ref.read(authServiceProvider).authStateChanges.listen(
      (user) {
        if (_manualAuth || _restoring || _disposed) return;
        if (ref.read(profileRepoProvider).isar.name != (user?.uid ?? 'guest'))
          _barrier(true);
        unawaited(_serialize(() => _transition(user?.uid)).catchError(_report));
      },
    );
  }

  void _report(Object error) {
    if (!_disposed)
      ref.read(accountSessionErrorProvider.notifier).state =
          'Cloud sync could not finish. Your data is safe on this device. Please retry.';
  }

  Future<void> signIn() => _serialize(() async {
    if (_restoring)
      throw StateError('Finish restoring before changing accounts.');
    _manualAuth = true;
    final sync = ref.read(firestoreSyncServiceProvider);
    var authAttempted = false;
    try {
      await sync.pauseAndDrainSync();
      authAttempted = true;
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null) await _transition(user.uid, force: true);
    } finally {
      _manualAuth = false;
      if (authAttempted) await _settleAuthBinding();
      if (!_restoring) {
        sync.resumeSync();
        await _detach();
        await _attach();
      }
    }
  });
  Future<void> signOut() => _serialize(() async {
    if (_restoring) throw StateError('Finish restoring before signing out.');
    _manualAuth = true;
    var authAttempted = false;
    _barrier(true);
    try {
      ref.read(firestoreSyncServiceProvider).pauseSync();
      await ref.read(remindersProvider.notifier).clearOnSignOut();
      await _detach();
      authAttempted = true;
      await ref.read(authServiceProvider).signOut();
      await _transition(null, force: true);
    } finally {
      _manualAuth = false;
      if (authAttempted) await _settleAuthBinding();
      _barrier(false);
      ref.read(firestoreSyncServiceProvider).resumeSync();
      await _detach();
      await _attach();
    }
  });
  Future<void> _settleAuthBinding() async {
    final uid = ref.read(authServiceProvider).uid;
    if (ref.read(profileRepoProvider).isar.name != (uid ?? 'guest')) {
      await _transition(uid, force: true);
    }
  }

  Future<void> ensureActive() => _serialize(() async {
    final uid = ref.read(authServiceProvider).uid;
    if (_hydratedAccount != (uid ?? 'guest') ||
        ref.read(profileRepoProvider).isar.name != (uid ?? 'guest')) {
      await _transition(uid, force: true);
    } else {
      ref.read(firestoreSyncServiceProvider).triggerFlush();
    }
  });
  Future<void> refresh() => _serialize(
    () => _transition(ref.read(authServiceProvider).uid, force: true),
  );

  void _barrier(bool enabled) {
    ref.read(accountTransitionProvider.notifier).state = enabled;
    ref.read(accountGenerationProvider.notifier).state++;
  }

  Future<void> _detach() async {
    final subscriptions = List<StreamSubscription>.of(_incoming);
    _incoming.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await _queueSubscription?.cancel();
    _queueSubscription = null;
    await Future.wait([
      ref.read(workoutRepoProvider).detachSync(),
      ref.read(mealRepoProvider).detachSync(),
      ref.read(dailyLogRepoProvider).detachSync(),
      ref.read(habitRepoProvider).detachSync(),
      ref.read(bodyStatsRepoProvider).detachSync(),
      ref.read(profileRepoProvider).detachSync(),
      ref.read(exerciseLogRepoProvider).detachSync(),
      ref.read(coachNoteRepoProvider).detachSync(),
      ref.read(badgeRepoProvider).detachSync(),
    ]);
  }

  Future<void> _bind(Isar database) async {
    await Future.wait([
      ref.read(workoutRepoProvider).init(database),
      ref.read(mealRepoProvider).init(database),
      ref.read(photoMealRepoProvider).init(database),
      ref.read(dailyLogRepoProvider).init(database),
      ref.read(habitRepoProvider).init(database),
      ref.read(bodyStatsRepoProvider).init(database),
      ref.read(mediaRepoProvider).init(database),
      ref.read(profileRepoProvider).init(database),
      ref.read(exerciseLogRepoProvider).init(database),
      ref.read(coachNoteRepoProvider).init(database),
      ref.read(badgeRepoProvider).init(database),
      ref.read(friendRepoProvider).init(database),
      ref.read(healthConnectServiceProvider).init(database),
    ]);
  }

  Future<void> _transition(String? uid, {bool force = false}) async {
    if (_disposed) return;
    final target = uid ?? 'guest';
    final oldDatabase = ref.read(profileRepoProvider).isar;
    if (!force && oldDatabase.name == target && _hydratedAccount == target)
      return;
    final sync = ref.read(firestoreSyncServiceProvider);
    _barrier(true);
    ref.read(accountHydratingProvider.notifier).state = true;
    ref.read(recoveredAccountProvider.notifier).state = null;
    sync.pauseSync();
    Isar? database;
    var fullyBound = false;
    try {
      await _detach();
      if (oldDatabase.name != target) await ref.read(remindersProvider.notifier).clearOnSignOut();
      database = await AppDatabaseManager.openDatabaseForUser(uid);
      await SchemaMigrationService.runStartupMigrations(database);
      await _bind(database);
      fullyBound = true;
      ref.read(accountGenerationProvider.notifier).state++;
      if (ref.read(authServiceProvider).uid != uid)
        throw StateError('Account changed while loading.');
      // Once every repository is bound, the offline view is safe to use while
      // cloud hydration continues; pending writes protect edits made meanwhile.
      _barrier(false);
      if (uid != null) {
        final restoreMarker = await database.appConfigs
            .where()
            .keyEqualTo('restore_reconciliation_pending')
            .findFirst();
        if (restoreMarker != null)
          await CloudRecordStore(database).enqueueSnapshot(replaceCloud: true);
        var remoteHasData = false;
        final profile = await sync.pullProfile();
        if (profile != null) {
          await ref.read(profileRepoProvider).importProfileFromCloud(profile);
          ref.read(recoveredAccountProvider.notifier).state = uid;
        }
        final store = CloudRecordStore(database);
        // Independent collection reads share the same pinned account. Keep request
        // concurrency bounded to avoid a burst on cold start/mobile connections.
        final names = store.collections.toList();
        for (var index = 0; index < names.length; index += 3) {
          await Future.wait(
            names.skip(index).take(3).map((name) async {
              final snapshot = await sync.pullCollection(name);
              if (snapshot.isNotEmpty) remoteHasData = true;
              if (ref.read(authServiceProvider).uid != uid)
                throw StateError('Account changed while loading.');
              if (name == 'badges') {
                await ref.read(badgeRepoProvider).importFromCloud(snapshot);
              } else {
                await store.apply(
                  name,
                  snapshot,
                  isCurrent: () =>
                      ref.read(authServiceProvider).uid == uid &&
                      identical(ref.read(profileRepoProvider).isar, database),
                );
              }
            }),
          );
        }
        if (profile == null) {
          if (!remoteHasData &&
              oldDatabase.name == 'guest' &&
              !identical(oldDatabase, database))
            await _adoptGuest(oldDatabase, database);
          sync.syncProfile(
            ref.read(profileRepoProvider).exportProfileForCloud(),
          );
          await store.enqueueSnapshot();
        }
      }
      _hydratedAccount = target;
      ref.read(accountSessionErrorProvider.notifier).state = null;
    } catch (error) {
      _report(error);
      // Never expose a previous account after Firebase has switched. A failed
      // hydration leaves the target's offline snapshot; a failed bind falls back
      // to guest so partially initialized repositories cannot span two accounts.
      final latestUid = ref.read(authServiceProvider).uid;
      if (!fullyBound || latestUid != uid) {
        final recovery = await AppDatabaseManager.openDatabaseForUser(
          latestUid,
        );
        await _bind(recovery);
        fullyBound = true;
      }
      rethrow;
    } finally {
      ref.read(accountHydratingProvider.notifier).state = false;
      _barrier(!fullyBound);
      if (fullyBound) {
        sync.resumeSync();
        await _attach();
        await ref.read(remindersProvider.notifier).queueSync();
      }
    }
  }

  Future<void> _adoptGuest(Isar guest, Isar target) async {
    final claim = await guest.appConfigs
        .where()
        .keyEqualTo('adopted_account')
        .findFirst();
    if (claim != null) return;
    // Preserve the guest recovery copy; never reuse it to seed a second account.
    final source = CloudRecordStore(guest),
        destination = CloudRecordStore(target);
    for (final name in source.collections) {
      await destination.apply(name, await source.export(name));
    }
    final profile = await guest.userProfiles.where().findFirst();
    if (profile != null) {
      final current = await target.userProfiles.where().findFirst();
      profile.id = current?.id ?? Isar.autoIncrement;
      await target.writeTxn(() async {
        if (await target.syncQueueItems
            .filter()
            .collectionEqualTo('_profile_')
            .isEmpty()) {
          await target.userProfiles.put(profile);
        }
      });
    }
    // These records are backup/local-only and contain account-local photo paths.
    final extras = <IsarCollection<dynamic>, IsarCollection<dynamic>>{
      guest.progressPhotos: target.progressPhotos,
      guest.scannedMealLogs: target.scannedMealLogs,
      guest.userFoodLogs: target.userFoodLogs,
    };
    for (final entry in extras.entries) {
      if (await entry.value.count() != 0) continue;
      final data = await entry.key.where().exportJson();
      await target.writeTxn(() async {
        await entry.value.importJson(data);
      });
    }
    await guest.writeTxn(() async {
      await guest.appConfigs.put(
        AppConfig(key: 'adopted_account', value: target.name),
      );
    });
  }

  Future<void> _attach() async {
    if (_disposed) return;
    final sync = ref.read(firestoreSyncServiceProvider);
    final database = ref.read(profileRepoProvider).isar;
    if (database.name != (ref.read(authServiceProvider).uid ?? 'guest')) return;
    ref.read(workoutRepoProvider).attachSync(sync);
    await ref.read(mealRepoProvider).attachSync(sync, listen: false);
    await ref.read(dailyLogRepoProvider).attachSync(sync, listen: false);
    ref.read(habitRepoProvider).attachSync(sync);
    ref.read(bodyStatsRepoProvider).attachSync(sync);
    ref.read(profileRepoProvider).attachSync(sync);
    ref.read(exerciseLogRepoProvider).attachSync(sync);
    ref.read(coachNoteRepoProvider).attachSync(sync);
    if (!sync.canSync || database.name != ref.read(authServiceProvider).uid)
      return;
    if (await database.appConfigs
        .where()
        .keyEqualTo('restore_reconciliation_pending')
        .isNotEmpty())
      return;
    final pendingRestore = await database.syncQueueItems
        .filter()
        .collectionEqualTo('_reconcile_')
        .isNotEmpty();
    if (pendingRestore) {
      _queueSubscription = database.syncQueueItems
          .watchLazy(fireImmediately: true)
          .listen((_) async {
            if (!_reattaching &&
                await database.syncQueueItems
                    .filter()
                    .collectionEqualTo('_reconcile_')
                    .isEmpty()) {
              if (_reattaching) return;
              _reattaching = true;
              await _queueSubscription?.cancel();
              _queueSubscription = null;
              try {
                if (identical(database, ref.read(profileRepoProvider).isar))
                  await _attach();
              } finally {
                _reattaching = false;
              }
            }
          });
      return;
    }
    await ref.read(badgeRepoProvider).attachSync(sync);
    final store = CloudRecordStore(database);
    final generation = ref.read(accountGenerationProvider);
    if (sync is FirestoreSyncService) {
      _incoming.add(
        sync
            .streamProfile()
            .asyncMap((profile) async {
              if (profile == null ||
                  _disposed ||
                  generation != ref.read(accountGenerationProvider))
                return;
              await ref
                  .read(profileRepoProvider)
                  .importProfileFromCloud(profile);
            })
            .listen((_) {}, onError: _report),
      );
    }
    for (final name in store.collections.where((name) => name != 'badges')) {
      _incoming.add(
        sync
            .streamCollection(name)
            .asyncMap(
              (snapshot) => store.apply(
                name,
                snapshot,
                isCurrent: () =>
                    !_disposed &&
                    generation == ref.read(accountGenerationProvider),
              ),
            )
            .listen((_) {}, onError: _report),
      );
    }
    // Public catalog updates never overwrite personal plans or queue cloud echoes.
    unawaited(
      Future.wait([
        ref.read(workoutRepoProvider).fetchGlobalPlans(),
        ref.read(mealRepoProvider).fetchGlobalPlans(),
      ]).catchError((Object error) {
        _report(error);
        return <void>[];
      }),
    );
  }

  Future<void> beforeRestore(Isar database) => _serialize(() async {
    if (_restoring || !identical(database, ref.read(profileRepoProvider).isar))
      throw StateError('Account changed before restore.');
    _restoring = true;
    _barrier(true);
    try {
      await ref.read(firestoreSyncServiceProvider).pauseAndDrainSync();
      await _detach();
    } catch (_) {
      _restoring = false;
      _barrier(false);
      ref.read(firestoreSyncServiceProvider).resumeSync();
      await _attach();
      rethrow;
    }
  });
  Future<void> afterRestore(Isar database, bool committed) => _serialize(
    () async {
      try {
        if (committed && database.name != 'guest') {
          _hydratedAccount = null;
          await CloudRecordStore(database).enqueueSnapshot(replaceCloud: true);
          _hydratedAccount = database.name;
        }
      } finally {
        _restoring = false;
        _barrier(false);
        ref.read(firestoreSyncServiceProvider).resumeSync();
        await _attach();
      }
    },
  );
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _queueSubscription?.cancel();
    for (final subscription in _incoming) {
      subscription.cancel();
    }
  }
}
