import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../interfaces/i_auth_service.dart';
import '../models/social_profile.dart';

class SocialSyncException implements Exception {
  final String code;
  final String message;
  const SocialSyncException(this.code, this.message);
  @override
  String toString() => message;
}

class SocialSyncService {
  final IAuthService _auth;
  final FirebaseFirestore _db;
  final String? _accountId;
  Timer? _debouncer;
  bool _disposed = false;
  Future<void>? _flushing;
  Map<String, dynamic>? _pendingProfile;
  int _profileRevision = 0;
  Future<void> _storageTail = Future<void>.value();

  SocialSyncService(
    this._auth, {
    FirebaseFirestore? firestore,
    String? accountId,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _accountId = accountId ?? _auth.uid;

  bool get canSync =>
      !_disposed &&
      _accountId != null &&
      _auth.isSignedIn &&
      _auth.uid == _accountId;
  String? get currentUid => canSync ? _accountId : null;
  String get _profileCacheKey =>
      'social_profile_outbox_v1_${Uri.encodeComponent(_accountId ?? '')}';

  String _requireAccount() {
    if (!canSync)
      throw const SocialSyncException(
        'account-changed',
        'Sign in again to continue sharing activity.',
      );
    return _accountId!;
  }

  void _validateFriend(String uid) {
    if (!isValidFriendId(uid) || uid == _accountId) {
      throw const SocialSyncException('invalid-id', 'Enter a valid friend ID.');
    }
  }

  DocumentReference<Map<String, dynamic>> _request(
    String target,
    String from,
  ) => _db
      .collection('friend_requests')
      .doc(target)
      .collection('requests')
      .doc(from);

  Future<T> _perform<T>(Future<T> Function(String uid) operation) async {
    final uid = _requireAccount();
    try {
      final result = await operation(uid);
      _requireAccount();
      return result;
    } on FirebaseException catch (error) {
      throw SocialSyncException(error.code, switch (error.code) {
        'permission-denied' =>
          'This activity is no longer shared with you, or the request changed. Refresh and try again.',
        'unavailable' || 'deadline-exceeded' =>
          'Could not connect. Check your connection and try again.',
        _ => 'Could not update friends. Please try again.',
      });
    }
  }

  Map<String, dynamic> _profileSnapshot(Map<String, dynamic> snapshot) => {
    ...snapshot,
    // Explicit nulls clear stale optional metrics during a merge. Sharing grants
    // remain owned solely by relationship actions.
    'todayScore': snapshot['todayScore'],
    'weekScore': snapshot['weekScore'],
    'latestBadge': snapshot['latestBadge'],
  }..remove('allowedReaders');

  /// Persist the latest small snapshot before debouncing. Access permissions are
  /// managed only by relationship actions and cannot be restored by a stale push.
  Future<void> pushProfile(SocialProfile profile) async {
    final uid = _requireAccount();
    if (profile.uid != uid)
      throw const SocialSyncException(
        'account-changed',
        'The active account changed.',
      );
    final data = _profileSnapshot(profile.toJson());
    _pendingProfile = data;
    _profileRevision++;
    await _storePendingProfile();
    _requireAccount();
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(seconds: 3), () {
      unawaited(
        flushProfile().catchError((Object _) {
          debugPrint('Social profile update remains pending for retry.');
        }),
      );
    });
  }

  Future<void> _storePendingProfile() {
    final operation = _storageTail.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final pending = _pendingProfile;
      if (pending == null) {
        await prefs.remove(_profileCacheKey);
      } else {
        await prefs.setString(_profileCacheKey, jsonEncode(pending));
      }
    });
    _storageTail = operation;
    return operation;
  }

  /// Awaitable on resume/background; failed updates remain account-scoped for retry.
  Future<void> flushProfile() {
    final existing = _flushing;
    if (existing != null) return existing;
    final operation = _flushProfile();
    _flushing = operation;
    return operation.whenComplete(() {
      if (identical(_flushing, operation)) _flushing = null;
    });
  }

  Future<void> _flushProfile() async {
    _debouncer?.cancel();
    final uid = _requireAccount();
    final prefs = await SharedPreferences.getInstance();
    _requireAccount();
    if (_pendingProfile == null) {
      final stored = prefs.getString(_profileCacheKey);
      if (stored != null) {
        try {
          final restored = _profileSnapshot(
            Map<String, dynamic>.from(jsonDecode(stored) as Map),
          );
          if (restored['uid'] == uid) _pendingProfile = restored;
        } catch (_) {
          await prefs.remove(_profileCacheKey);
        }
      }
    }
    while (_pendingProfile != null) {
      _requireAccount();
      final data = _pendingProfile!;
      final revision = _profileRevision;
      await _perform(
        (account) => _db
            .collection('social_profiles')
            .doc(account)
            .set(data, SetOptions(merge: true)),
      );
      if (revision == _profileRevision) {
        _pendingProfile = null;
        await _storePendingProfile();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _debouncer?.cancel();
  }

  Stream<SocialProfile?> streamFriendProfile(String friendUid) {
    if (!canSync) return const Stream.empty();
    return _db.collection('social_profiles').doc(friendUid).snapshots().map((
      snap,
    ) {
      _requireAccount();
      return snap.exists && snap.data() != null
          ? SocialProfile.fromJson({...snap.data()!, 'uid': snap.id})
          : null;
    });
  }

  Future<SocialProfile?> fetchProfileOnce(String uid) => _perform((_) async {
    final snap = await _db.collection('social_profiles').doc(uid).get();
    return snap.exists && snap.data() != null
        ? SocialProfile.fromJson({...snap.data()!, 'uid': snap.id})
        : null;
  });

  List<String> _roster(Map<String, dynamic>? data) =>
      (data?['allowedReaders'] as List? ?? [])
          .whereType<String>()
          .where((uid) => uid != _accountId && isValidFriendId(uid))
          .toSet()
          .toList()
        ..sort();

  static bool isValidFriendId(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{20,128}$').hasMatch(value);

  /// Only confirmed server membership may remove a cached local connection.
  Stream<List<String>> streamFriendUids() {
    final uid = _requireAccount();
    // A transform chain propagates cancellation directly to Firestore, including
    // when the source is idle. No generator may hold account teardown open.
    return _db
        .collection('social_profiles')
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) {
          _requireAccount();
          return !snapshot.metadata.isFromCache &&
              !snapshot.metadata.hasPendingWrites;
        })
        .map((snapshot) => _roster(snapshot.data()))
        .distinct((previous, next) => listEquals(previous, next))
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw SocialSyncException(
              error.code,
              'Could not refresh your connections. Please try again.',
            );
          }
          throw error;
        });
  }

  /// Outgoing grants are the durable roster; transient acknowledgements are not.
  Future<List<String>> getFriendUids() => _perform((uid) async {
    final snap = await _db
        .collection('social_profiles')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    return _roster(snap.data());
  });

  Future<void> sendFriendRequest(
    String targetUid,
    String myName,
    String? myAvatar,
  ) async {
    try {
      await _perform((uid) async {
        _validateFriend(targetUid);
        if (myName.trim().length > 120 || (myAvatar?.length ?? 0) > 2048) {
          throw const SocialSyncException(
            'invalid-profile',
            'Update your profile name or avatar before sending a request.',
          );
        }
        final request = _request(targetUid, uid);
        await _db.runTransaction(
          (transaction) async {
            _requireAccount();
            final existing = (await transaction.get(request)).data();
            _requireAccount();
            if (existing != null) {
              if (existing['accepted'] == false &&
                  existing['kind'] != 'acceptance') {
                throw const SocialSyncException(
                  'already-pending',
                  'Your request is already waiting for approval.',
                );
              }
              throw const SocialSyncException(
                'request-accepted',
                'This request has already been accepted. Refresh your connections.',
              );
            }
            transaction.set(request, {
              'kind': 'request',
              'requestId': const Uuid().v4(),
              'fromUid': uid,
              'fromName': myName.trim(),
              'fromAvatar': myAvatar,
              'sentAt': FieldValue.serverTimestamp(),
              'accepted': false,
            });
          },
          timeout: const Duration(seconds: 15),
          maxAttempts: 3,
        );
      });
    } on SocialSyncException catch (error) {
      if (error.code == 'permission-denied') {
        throw const SocialSyncException(
          'id-unavailable',
          'This ID is not available. Check the ID or ask your friend to open the app and finish syncing.',
        );
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _requestMaps(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs.map((doc) => {...doc.data(), 'fromUid': doc.id}).toList();
  Stream<List<Map<String, dynamic>>> streamFriendRequests() {
    if (!canSync) return const Stream.empty();
    return _db
        .collection('friend_requests')
        .doc(_accountId)
        .collection('requests')
        .where('accepted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          _requireAccount();
          return _requestMaps(snapshot);
        });
  }

  Query<Map<String, dynamic>> _acceptances(String uid) => _db
      .collection('friend_requests')
      .doc(uid)
      .collection('requests')
      .where('kind', isEqualTo: 'acceptance')
      .where('accepted', isEqualTo: true);
  Stream<List<Map<String, dynamic>>> streamPendingAcceptances() {
    if (!canSync) return const Stream.empty();
    return _acceptances(_accountId!).snapshots().map((snapshot) {
      _requireAccount();
      return _requestMaps(snapshot);
    });
  }

  Future<List<Map<String, dynamic>>> getPendingAcceptances() =>
      _perform((uid) async => _requestMaps(await _acceptances(uid).get()));

  Future<void> acceptFriendRequest(String requesterUid) => _perform((
    uid,
  ) async {
    _validateFriend(requesterUid);
    final request = _request(uid, requesterUid);
    final marker = _request(requesterUid, uid);
    await _db.runTransaction(
      (transaction) async {
        _requireAccount();
        final incoming = (await transaction.get(request)).data();
        _requireAccount();
        if (incoming == null ||
            incoming['fromUid'] != requesterUid ||
            incoming['kind'] == 'acceptance' ||
            (incoming['accepted'] == true && incoming['kind'] != 'request')) {
          throw const SocialSyncException(
            'request-changed',
            'This request is no longer available. Refresh your requests.',
          );
        }
        final requestId = incoming['requestId'] as String? ?? const Uuid().v4();
        transaction.set(_db.collection('social_profiles').doc(uid), {
          'uid': uid,
          'allowedReaders': FieldValue.arrayUnion([requesterUid]),
        }, SetOptions(merge: true));
        transaction.update(request, {
          'kind': 'request',
          'requestId': requestId,
          'accepted': true,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        // Create OR replace a reciprocal pending request under constrained rules.
        transaction.set(marker, {
          'kind': 'acceptance',
          'requestId': requestId,
          'fromUid': uid,
          'accepted': true,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  });

  Future<void> declineFriendRequest(String requesterUid) => _perform((
    uid,
  ) async {
    _validateFriend(requesterUid);
    final request = _request(uid, requesterUid);
    await _db.runTransaction(
      (transaction) async {
        final incoming = (await transaction.get(request)).data();
        _requireAccount();
        if (incoming == null) return; // Repeated decline is already complete.
        if (incoming['accepted'] != false || incoming['kind'] == 'acceptance') {
          throw const SocialSyncException(
            'request-changed',
            'This request has changed. Refresh your connections before continuing.',
          );
        }
        transaction.delete(request);
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  });

  Future<void> removeFriendAccess(String friendUid) => _perform((uid) async {
    _validateFriend(friendUid);
    final profile = _db.collection('social_profiles').doc(uid);
    await _db.runTransaction(
      (transaction) async {
        await transaction.get(profile);
        _requireAccount();
        transaction.set(profile, {
          'uid': uid,
          'allowedReaders': FieldValue.arrayRemove([friendUid]),
        }, SetOptions(merge: true));
        transaction.delete(_request(uid, friendUid));
        transaction.delete(_request(friendUid, uid));
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  });

  Future<void> clearAcceptanceMarker(String friendUid) => _perform((uid) async {
    final marker = _request(uid, friendUid);
    await _db.runTransaction(
      (transaction) async {
        final data = (await transaction.get(marker)).data();
        _requireAccount();
        if (data?['kind'] == 'acceptance') transaction.delete(marker);
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  });

  /// Caller persists the friend locally before acknowledging. False means the
  /// relationship was removed/replaced and that local insertion must be undone.
  Future<bool> processPendingAcceptance(
    String friendUid, {
    String? requestId,
  }) => _perform((uid) async {
    _validateFriend(friendUid);
    final marker = _request(uid, friendUid);
    final original = _request(friendUid, uid);
    return _db.runTransaction<bool>(
      (transaction) async {
        _requireAccount();
        final acknowledgement = (await transaction.get(marker)).data();
        final source = (await transaction.get(original)).data();
        _requireAccount();
        if (acknowledgement?['kind'] != 'acceptance' ||
            acknowledgement?['accepted'] != true ||
            source?['kind'] != 'request' ||
            source?['accepted'] != true ||
            acknowledgement?['requestId'] is! String ||
            acknowledgement?['requestId'] != source?['requestId'] ||
            (requestId != null && acknowledgement?['requestId'] != requestId))
          return false;
        transaction.set(_db.collection('social_profiles').doc(uid), {
          'uid': uid,
          'allowedReaders': FieldValue.arrayUnion([friendUid]),
        }, SetOptions(merge: true));
        transaction.delete(marker);
        return true;
      },
      timeout: const Duration(seconds: 15),
      maxAttempts: 3,
    );
  });
}
