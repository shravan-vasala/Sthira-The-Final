import 'dart:async';
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/badge.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/sync_queue_item.dart';

class BadgeRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  int _syncGeneration = 0;
  String? _attachedUid;
  final List<StreamSubscription> _syncSubscriptions = [];

  Stream<void> get watchUpdates =>
      _isar.badges.watchLazy(fireImmediately: true);

  Future<void> detachSync() async {
    _syncGeneration++;
    _attachedUid = null;
    final toCancel = List<StreamSubscription>.from(_syncSubscriptions);
    _syncSubscriptions.clear();
    for (final sub in toCancel) {
      try {
        await sub.cancel();
      } catch (e) {
        // ignore errors during teardown
      }
    }
    _sync = null;
  }

  Future<void> attachSync(ICloudSyncService sync) async {
    await detachSync();
    _syncGeneration++; // Synchronous unique generation
    final currentGen = _syncGeneration;
    _sync = sync;
    final targetUid = sync.currentUid;
    _attachedUid = targetUid;

    if (sync.canSync) {
      _syncSubscriptions.add(
        sync.streamCollection('badges').listen((data) async {
          if (currentGen != _syncGeneration) return;
          for (final entry in data.entries) {
            if (currentGen != _syncGeneration) return;
            final b = Badge.fromJson(entry.value);
            await _mergeCloudBadgeSafe(
              b,
              () =>
                  currentGen == _syncGeneration &&
                  sync.currentUid == targetUid &&
                  _attachedUid == targetUid,
            );
          }
        }),
      );
    }
  }

  void dispose() {
    detachSync();
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    await _seedDefaultBadges();
  }

  Future<void> _seedDefaultBadges() async {
    final defaults = [
      Badge(
        id: 'first_workout',
        category: 'workout',
        title: 'Welcome to the Iron',
        description: 'Log your first workout',
        iconEmoji: '🏋️',
        requiredProgress: 1,
      ),
      Badge(
        id: 'workout_10',
        category: 'workout',
        title: 'Consistency Key',
        description: 'Log 10 workouts',
        iconEmoji: '🔥',
        requiredProgress: 10,
      ),
      Badge(
        id: 'workout_50',
        category: 'workout',
        title: 'Iron Lifter',
        description: 'Log 50 workouts',
        iconEmoji: '🦍',
        requiredProgress: 50,
      ),
      Badge(
        id: 'meal_days_7',
        category: 'meal',
        title: 'Meal momentum',
        description:
            'Record a meal on 7 different days. The days do not need to be consecutive.',
        iconEmoji: '🍽️',
        requiredProgress: 7,
      ),
      Badge(
        id: 'meal_days_30',
        category: 'meal',
        title: 'Steady tracker',
        description:
            'Record a meal on 30 different days. Every recorded day counts, even after a break.',
        iconEmoji: '🌱',
        requiredProgress: 30,
      ),
      Badge(
        id: 'streak_3',
        category: 'streak',
        title: 'Momentum',
        description: 'Workout 3 days in a row',
        iconEmoji: '⚡',
        requiredProgress: 3,
      ),
      Badge(
        id: 'streak_7',
        category: 'streak',
        title: 'Unstoppable',
        description: 'Workout 7 days in a row',
        iconEmoji: '🔥',
        requiredProgress: 7,
      ),
    ];

    await _isar.writeTxn(() async {
      for (final b in defaults) {
        if (await _isar.badges.where().idEqualTo(b.id).findFirst() == null) {
          await _isar.badges.put(b);
        }
      }
    });
  }

  List<Badge> getAllBadges() {
    return _isar.badges.where().findAllSync();
  }

  Badge? getBadge(String id) {
    return _isar.badges.where().idEqualTo(id).findFirstSync();
  }

  Future<void> saveBadge(Badge badge, {bool Function()? isCurrent}) async {
    final database = _isar;
    final sync = _sync;
    bool valid() => identical(_isar, database) && (isCurrent?.call() ?? true);
    if (!valid()) return;
    await database.writeTxn(() async {
      if (!valid()) return;
      final existing = await database.badges
          .where()
          .idEqualTo(badge.id)
          .findFirst();
      if (!valid()) return;
      final saved = existing?.isUnlocked == true && !badge.isUnlocked
          ? existing!
          : badge;
      if (existing != null) saved.idInternal = existing.idInternal;
      await database.badges.put(saved);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'badges',
            docId: saved.id,
            payload: jsonEncode(saved.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (valid() && identical(_sync, sync)) sync?.triggerFlush();
  }

  Future<void> _mergeCloudBadgeSafe(
    Badge cloudBadge, [
    bool Function()? isValidContext,
  ]) async {
    final database = _isar;
    await database.writeTxn(() async {
      if (!identical(_isar, database)) return;
      if (isValidContext != null && !isValidContext()) return;

      final existing = await database.badges
          .where()
          .idEqualTo(cloudBadge.id)
          .findFirst();

      if (existing == null) {
        await database.badges.put(cloudBadge);
        return;
      }

      int newProgress = existing.currentProgress;
      if (cloudBadge.currentProgress > existing.currentProgress) {
        newProgress = cloudBadge.currentProgress;
      }

      DateTime? newUnlockedAt = existing.unlockedAt;
      if (cloudBadge.unlockedAt != null) {
        if (newUnlockedAt == null ||
            cloudBadge.unlockedAt!.isBefore(newUnlockedAt)) {
          newUnlockedAt = cloudBadge.unlockedAt;
        }
      }

      final updated = existing.copyWith(
        currentProgress: newProgress,
        unlockedAt: newUnlockedAt,
      );

      if (updated.currentProgress == existing.currentProgress &&
          updated.unlockedAt == existing.unlockedAt) {
        return;
      }

      updated.idInternal = existing.idInternal;
      await database.badges.put(updated);
    });
  }

  /// Bulk import from Firestore (used on new-device sign-in).
  Future<void> importFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    for (final entry in cloudData.entries) {
      if (!identical(_isar, database)) return;
      final cloudBadge = Badge.fromJson(entry.value);
      await _mergeCloudBadgeSafe(cloudBadge, () => identical(_isar, database));
    }
  }

  /// Bulk export to Firestore (used on manual backup or sync).
  Map<String, Map<String, dynamic>> exportForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final badges = getAllBadges();
    for (final badge in badges) {
      if (badge.isUnlocked) {
        result[badge.id] = badge.toJson();
      } else if (badge.currentProgress > 0) {
        result[badge.id] = Badge(
          id: badge.id,
          category: badge.category,
          title: badge.title,
          description: badge.description,
          iconEmoji: badge.iconEmoji,
          requiredProgress: badge.requiredProgress,
          currentProgress: badge.currentProgress,
        ).toJson();
      }
    }
    return result;
  }

  Future<void> clearAllProgressForDebug() async {
    final badges = getAllBadges();
    for (final badge in badges) {
      final newBadge = Badge(
        id: badge.id,
        category: badge.category,
        title: badge.title,
        description: badge.description,
        iconEmoji: badge.iconEmoji,
        requiredProgress: badge.requiredProgress,
        currentProgress: 0,
        unlockedAt: null,
      );
      newBadge.idInternal = badge.idInternal;
      await _isar.writeTxn(() async {
        await _isar.badges.put(newBadge);
      });
    }
  }
}
