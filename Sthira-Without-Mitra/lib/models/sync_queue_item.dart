import 'package:isar/isar.dart';

part 'sync_queue_item.g.dart';

@collection
class SyncQueueItem {
  Id id = Isar.autoIncrement;

  @Index()
  final String collection;

  @Index()
  final String docId;

  final String payload;

  final DateTime timestamp;

  @Index(composite: [CompositeIndex('timestamp')])
  final String uid;

  bool quarantined;
  String? lastError;
  int attempts;

  SyncQueueItem({
    required this.collection,
    required this.docId,
    required this.payload,
    required this.timestamp,
    required this.uid,
    this.quarantined = false,
    this.lastError,
    this.attempts = 0,
  });
}
