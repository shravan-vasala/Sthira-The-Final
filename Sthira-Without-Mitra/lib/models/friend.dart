import 'package:isar/isar.dart';

part 'friend.g.dart';

@collection
class Friend {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  late String name;
  String? avatarUrl;
  late DateTime addedAt;
}
