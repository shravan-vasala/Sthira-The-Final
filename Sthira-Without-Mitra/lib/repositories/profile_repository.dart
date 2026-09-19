import '../services/cloud_record_store.dart';
import '../models/app_config.dart';
import 'package:isar/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../interfaces/i_cloud_sync_service.dart';
import 'dart:convert';
import '../models/sync_queue_item.dart';

class ProfileRepository {
  late Isar _isar;
  Isar get isar => _isar;
  final _secureStorage = const FlutterSecureStorage(aOptions: AndroidOptions());
  ICloudSyncService? _sync;

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    if (_isar.userProfiles.where().countSync() == 0) {
      // Bootstrap defaults are not an intentional edit or cloud upload.
      await isar.writeTxn(() async {
        await isar.userProfiles.put(UserProfile());
      });
    }
  }

  Future<String?> getSecureGeminiKey() async {
    try {
      return await _secureStorage
          .read(key: 'gemini_api_key')
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Secure storage error or timeout: $e');
      return null;
    }
  }

  Future<void> saveSecureGeminiKey(String key) async {
    await _secureStorage.write(key: 'gemini_api_key', value: key);
  }

  Future<void> deleteSecureGeminiKey() async {
    await _secureStorage.delete(key: 'gemini_api_key');
  }

  UserProfile getProfile() {
    return _isar.userProfiles.where().findFirstSync() ?? UserProfile();
  }

  Stream<UserProfile?> watchProfile() {
    return _isar.userProfiles.where().watch(fireImmediately: true).map((
      profiles,
    ) {
      return profiles.isNotEmpty ? profiles.first : null;
    });
  }

  Future<void> saveProfile(UserProfile profile) async {
    final database = _isar;
    final sync = _sync;
    await database.writeTxn(() async {
      final existing = await database.userProfiles.where().findFirst();
      if (existing != null) profile.id = existing.id;
      await database.userProfiles.put(profile);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: '_profile_',
            docId: 'profile',
            payload: jsonEncode(profile.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(database, _isar)) sync?.triggerFlush();
  }

  Future<void> updateName(String name) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(name: name));
  }

  Future<void> updateHeight(double height) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(height: height));
  }

  Future<void> updateTargetWeight(double weight) async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(targetWeight: weight));
  }

  Future<void> toggleUnit() async {
    final profile = getProfile();
    await saveProfile(profile.copyWith(useKg: !profile.useKg));
  }

  // ── Cloud sync helpers ──

  Future<void> importProfileFromCloud(Map<String, dynamic>? cloudData) async {
    if (cloudData != null) {
      final profile = UserProfile.fromJson(cloudData);
      // We must preserve the existing Isar id if it exists, or clear it to let Isar assign one
      final existing = getProfile();
      profile.id = existing.id;
      final database = _isar;
      await database.writeTxn(() async {
        if (!identical(database, _isar)) return;
        if (await database.appConfigs
            .where()
            .keyEqualTo('restore_reconciliation_pending')
            .isNotEmpty())
          return;
        final pending = await database.syncQueueItems
            .filter()
            .collectionEqualTo('_profile_')
            .findFirst();
        if (pending != null) return;
        final metadata = await database.appConfigs
            .where()
            .keyEqualTo(CloudRecordStore.versionKey('_profile_', 'profile'))
            .findFirst();
        final remembered = metadata == null
            ? null
            : DateTime.tryParse(
                '${(jsonDecode(metadata.value) as Map)['updatedAt']}',
              );
        final incoming = CloudRecordStore.recordVersion(cloudData);
        if (remembered != null &&
            (incoming == null || incoming.isBefore(remembered)))
          return;
        await database.userProfiles.put(profile);
        if (incoming != null)
          await CloudRecordStore.rememberVersion(
            database,
            '_profile_',
            'profile',
            incoming,
          );
      });
    }
  }

  Map<String, dynamic> exportProfileForCloud() {
    return getProfile().toJson();
  }
}
