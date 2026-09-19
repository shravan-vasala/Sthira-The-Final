import 'package:isar/isar.dart';

abstract class ICloudSyncService {
  bool get canSync;
  String? get currentUid;

  Stream<int> get pendingCountStream;
  Future<void> flushNow();

  void pauseSync();
  Future<void> pauseAndDrainSync();
  void resumeSync();

  void syncToCloud(String collection, String docId, Map<String, dynamic> data);

  void deleteFromCloud(String collection, String docId);

  void syncProfile(Map<String, dynamic> data);
  Future<void> pushProfileNow(Map<String, dynamic> data);

  void queueSyncInTxn(
    Isar isar,
    String collection,
    String docId,
    Map<String, dynamic> data,
  );
  void queueDeleteInTxn(Isar isar, String collection, String docId);
  void queueProfileInTxn(Isar isar, Map<String, dynamic> data);
  void triggerFlush();

  Future<Map<String, Map<String, dynamic>>> pullCollection(String collection);

  Stream<Map<String, Map<String, dynamic>>> streamCollection(String collection);

  Future<Map<String, Map<String, dynamic>>> pullGlobalCollection(
    String collection,
  );

  Future<Map<String, dynamic>?> pullProfile();

  Future<bool> hasCloudData();

  Future<void> bulkSync(
    String collection,
    Map<String, Map<String, dynamic>> docs,
  );
}
