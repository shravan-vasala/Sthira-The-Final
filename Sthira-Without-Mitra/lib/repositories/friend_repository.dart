import 'package:isar/isar.dart';
import '../models/friend.dart';

class FriendRepository {
  late Isar isar;

  FriendRepository(this.isar);

  Future<void> init(Isar newIsar) async => isar = newIsar;

  List<Friend> getAllFriends() =>
      isar.friends.where().sortByAddedAtDesc().findAllSync();

  Friend? getFriend(String uid) =>
      isar.friends.where().uidEqualTo(uid).findFirstSync();

  /// Refresh shared identity without resetting when the connection was added.
  Future<void> addFriend(String uid, String name, {String? avatarUrl}) async {
    final database = isar;
    await database.writeTxn(() async {
      if (!identical(isar, database)) {
        throw StateError('The active account changed.');
      }
      final existing = await database.friends
          .where()
          .uidEqualTo(uid)
          .findFirst();
      if (!identical(isar, database)) {
        throw StateError('The active account changed.');
      }
      final friend = Friend()
        ..id = existing?.id ?? Isar.autoIncrement
        ..uid = uid
        ..name = name
        ..avatarUrl = avatarUrl
        ..addedAt = existing?.addedAt ?? DateTime.now();
      await database.friends.put(friend);
    });
  }

  Future<void> removeFriend(String uid) async {
    final database = isar;
    await database.writeTxn(() async {
      if (!identical(isar, database)) {
        throw StateError('The active account changed.');
      }
      final friend = await database.friends.where().uidEqualTo(uid).findFirst();
      if (!identical(isar, database)) {
        throw StateError('The active account changed.');
      }
      if (friend != null) await database.friends.delete(friend.id);
    });
  }
}
