import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudSnapshot extends MapBase<String, Map<String, dynamic>> {
  CloudSnapshot(
    this.documents, {
    this.authoritative = false,
    this.removedIds = const {},
    this.isComplete = true,
  });
  final Map<String, Map<String, dynamic>> documents;
  final bool authoritative;
  final Set<String> removedIds;
  final bool isComplete;
  @override
  Map<String, dynamic>? operator [](Object? key) => documents[key];
  @override
  void operator []=(String key, Map<String, dynamic> value) =>
      documents[key] = value;
  @override
  Iterable<String> get keys => documents.keys;
  @override
  void clear() => documents.clear();
  @override
  Map<String, dynamic>? remove(Object? key) => documents.remove(key);
}

class CloudWrite {
  const CloudWrite(
    this.collection,
    this.docId,
    this.data, {
    this.delete = false,
  });
  final String collection;
  final String docId;
  final Map<String, dynamic> data;
  final bool delete;
}

abstract class CloudSyncTransport {
  Future<void> commit(String uid, List<CloudWrite> writes);
  Future<CloudSnapshot> readCollection(String uid, String collection);
  Stream<CloudSnapshot> watchCollection(String uid, String collection);
  Future<Map<String, dynamic>?> readProfile(String uid);
  Stream<Map<String, dynamic>?> watchProfile(String uid);
  Future<Map<String, Map<String, dynamic>>> readGlobal(String collection);
}

class FirestoreTransport implements CloudSyncTransport {
  FirestoreTransport([FirebaseFirestore? firestore]) : _firestore = firestore;
  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  @override
  Future<void> commit(String uid, List<CloudWrite> writes) async {
    if (writes.isEmpty) return;
    final root = _db.collection('users').doc(uid);
    final batch = _db.batch();
    for (final write in writes) {
      if (write.collection == '_profile_') {
        // Replace the entire profile map, preserving unrelated root metadata.
        batch.set(root, {
          'profile': write.data,
          'lastSyncedAt': FieldValue.serverTimestamp(),
        }, SetOptions(mergeFields: ['profile', 'lastSyncedAt']));
      } else {
        final document = root.collection(write.collection).doc(write.docId);
        if (write.delete) {
          batch.delete(document);
        } else {
          batch.set(document, write.data);
        }
      }
    }
    await batch.commit();
  }

  @override
  Future<CloudSnapshot> readCollection(String uid, String collection) async {
    final result = <String, Map<String, dynamic>>{};
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .doc(uid)
        .collection(collection)
        .orderBy(FieldPath.documentId)
        .limit(400);
    DocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      final page = await (last == null ? query : query.startAfterDocument(last))
          .get(const GetOptions(source: Source.server));
      for (final doc in page.docs) {
        result[doc.id] = doc.data();
      }
      if (page.docs.length < 400) break;
      last = page.docs.last;
    }
    return CloudSnapshot(result, authoritative: true);
  }

  @override
  Stream<CloudSnapshot> watchCollection(String uid, String collection) async* {
    var receivedServerSnapshot = false;
    await for (final snapshot
        in _db
            .collection('users')
            .doc(uid)
            .collection(collection)
            .snapshots(includeMetadataChanges: true)) {
      final authoritative =
          !snapshot.metadata.isFromCache && !snapshot.metadata.hasPendingWrites;
      final complete = !receivedServerSnapshot;
      final documents = complete
          ? {for (final document in snapshot.docs) document.id: document.data()}
          : {
              for (final change in snapshot.docChanges)
                if (change.type != DocumentChangeType.removed &&
                    change.doc.data() != null)
                  change.doc.id: change.doc.data()!,
            };
      yield CloudSnapshot(
        documents,
        authoritative: authoritative,
        isComplete: complete,
        removedIds: authoritative
            ? snapshot.docChanges
                  .where((change) => change.type == DocumentChangeType.removed)
                  .map((change) => change.doc.id)
                  .toSet()
            : {},
      );
      if (authoritative) receivedServerSnapshot = true;
    }
  }

  @override
  Future<Map<String, dynamic>?> readProfile(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    final profile = snapshot.data()?['profile'];
    return profile is Map ? Map<String, dynamic>.from(profile) : null;
  }

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .where(
          (snapshot) =>
              !snapshot.metadata.isFromCache &&
              !snapshot.metadata.hasPendingWrites,
        )
        .map((snapshot) {
          final profile = snapshot.data()?['profile'];
          return profile is Map ? Map<String, dynamic>.from(profile) : null;
        });
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readGlobal(
    String collection,
  ) async {
    final snapshot = await _db.collection(collection).get();
    return {for (final d in snapshot.docs) d.id: d.data()};
  }
}
