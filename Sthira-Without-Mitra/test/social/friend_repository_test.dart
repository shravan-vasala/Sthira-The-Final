import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/repositories/friend_repository.dart';
import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late FriendRepository repository;
  setUp(() async {
    database = await setUpTestIsar();
    repository = FriendRepository(database);
  });
  tearDown(() => tearDownTestIsar(database));

  test(
    'recovering changed name/avatar preserves the original connection identity and date',
    () async {
      await repository.addFriend(
        'friend',
        'Old name',
        avatarUrl: 'assets/old.png',
      );
      final before = repository.getFriend('friend')!;
      await repository.addFriend('friend', 'New name');
      final after = repository.getFriend('friend')!;
      expect(after.id, before.id);
      expect(after.addedAt, before.addedAt);
      expect(after.name, 'New name');
      expect(after.avatarUrl, isNull);
      expect(repository.getAllFriends(), hasLength(1));
    },
  );

  test(
    'concurrent recovery updates do not duplicate or recreate the connection',
    () async {
      await repository.addFriend('friend', 'Original');
      final before = repository.getFriend('friend')!;
      await Future.wait([
        repository.addFriend('friend', 'Updated A'),
        repository.addFriend('friend', 'Updated B'),
      ]);
      expect(database.friends.countSync(), 1);
      final after = repository.getFriend('friend')!;
      expect(after.id, before.id);
      expect(after.addedAt, before.addedAt);
      expect(after.name, anyOf('Updated A', 'Updated B'));
      await repository.removeFriend('friend');
      expect(repository.getAllFriends(), isEmpty);
    },
  );

  test(
    'repository rebind prevents queued old-account friend insertion',
    () async {
      final other = await setUpTestIsar();
      try {
        final pending = repository.addFriend('friend', 'Old account');
        final checked = expectLater(pending, throwsStateError);
        await repository.init(other);
        await checked;
        expect(other.friends.countSync(), 0);
        expect(database.friends.countSync(), 0);
      } finally {
        await repository.init(database);
        await tearDownTestIsar(other);
      }
    },
  );
}
