import 'dart:async';
import '../repositories/friend_repository.dart';
import 'social_sync_service.dart';

/// Serializes relationship recovery within a captured account lifetime.
class SocialRelationshipCoordinator {
  final SocialSyncService service;
  final FriendRepository friends;
  final bool Function() isCurrent;
  final void Function(Object error)? onError;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  StreamSubscription<List<String>>? _rosterSubscription;
  int _acceptanceEpoch = 0;
  int _rosterEpoch = 0;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;
  SocialRelationshipCoordinator({
    required this.service,
    required this.friends,
    required this.isCurrent,
    this.onError,
  });
  bool get _active => !_disposed && isCurrent() && service.canSync;

  void start() {
    if (!_active || _subscription != null) return;
    _enqueue(recoverRoster);
    _listen();
    _listenRoster();
  }

  void _listen() {
    if (!_active || _subscription != null) return;
    final epoch = ++_acceptanceEpoch;
    _subscription = service.streamPendingAcceptances().listen(
      (pending) {
        _enqueue(() => _accept(pending));
      },
      onError: (Object error) {
        if (epoch != _acceptanceEpoch) return;
        _acceptanceEpoch++;
        unawaited(_subscription?.cancel());
        _subscription = null;
        if (_active) onError?.call(error);
      },
      onDone: () {
        if (epoch == _acceptanceEpoch) _subscription = null;
      },
    );
  }

  void _listenRoster() {
    if (!_active || _rosterSubscription != null) return;
    final epoch = ++_rosterEpoch;
    _rosterSubscription = service.streamFriendUids().listen(
      (_) => _enqueue(recoverRoster),
      onError: (Object error) {
        if (epoch != _rosterEpoch) return;
        _rosterEpoch++;
        unawaited(_rosterSubscription?.cancel());
        _rosterSubscription = null;
        if (_active) onError?.call(error);
      },
      onDone: () {
        if (epoch == _rosterEpoch) _rosterSubscription = null;
      },
    );
  }

  /// Keep removal after earlier recovery work so a late profile fetch cannot
  /// recreate the local connection that the user just removed.
  Future<void> removeFriend(String uid) {
    final operation = _tail.then((_) async {
      if (!_active) {
        throw const SocialSyncException(
          'account-changed',
          'The active account changed.',
        );
      }
      await service.removeFriendAccess(uid);
      if (!_active) return;
      await friends.removeFriend(uid);
    });
    _tail = operation.catchError((Object error) {
      if (_active) onError?.call(error);
    });
    return operation;
  }

  void _enqueue(Future<void> Function() work) {
    _tail = _tail
        .then((_) async {
          if (_active) await work();
        })
        .catchError((Object error) {
          if (_active) onError?.call(error);
        });
  }

  Future<void> recoverRoster() async {
    if (!_active) return;
    final roster = await service.getFriendUids();
    if (!_active) return;
    for (final friend in friends.getAllFriends()) {
      if (!_active) return;
      if (!roster.contains(friend.uid)) await friends.removeFriend(friend.uid);
    }
    for (final uid in roster) {
      if (!_active) return;
      try {
        final profile = await service.fetchProfileOnce(uid);
        if (!_active) return;
        if (profile != null)
          await friends.addFriend(
            uid,
            profile.name,
            avatarUrl: profile.avatarUrl,
          );
      } catch (error) {
        if (!_active) return;
        // Missing access or one temporarily unavailable profile must not prevent
        // the remaining connections from being recovered.
        if (error is! SocialSyncException ||
            error.code != 'permission-denied') {
          onError?.call(error);
        }
      }
    }
  }

  Future<void> _accept(List<Map<String, dynamic>> pending) async {
    for (final marker in pending) {
      if (!_active) return;
      final uid = marker['fromUid'] as String?;
      final requestId = marker['requestId'] as String?;
      if (uid == null || requestId == null) continue;
      try {
        final profile = await service.fetchProfileOnce(uid);
        if (!_active) return;
        // Missing/failed profiles never consume the acknowledgement.
        if (profile == null) continue;
        await friends.addFriend(
          uid,
          profile.name,
          avatarUrl: profile.avatarUrl,
        );
        if (!_active) return;
        final accepted = await service.processPendingAcceptance(
          uid,
          requestId: requestId,
        );
        if (!_active) return;
        if (!accepted) {
          final roster = await service.getFriendUids();
          if (_active && !roster.contains(uid)) await friends.removeFriend(uid);
        }
      } catch (error) {
        if (!_active) return;
        // One stale/unavailable profile must not block other accepted friends.
        onError?.call(error);
      }
    }
  }

  /// Retry after resume/reconnection even if a failed snapshot did not change.
  Future<void> refresh() {
    _listen();
    _listenRoster();
    _enqueue(() async {
      await recoverRoster();
      if (!_active) return;
      final pending = await service.getPendingAcceptances();
      if (_active) await _accept(pending);
    });
    return _tail;
  }

  void dispose() {
    _disposed = true;
    _acceptanceEpoch++;
    _rosterEpoch++;
    unawaited(_subscription?.cancel());
    unawaited(_rosterSubscription?.cancel());
  }
}
