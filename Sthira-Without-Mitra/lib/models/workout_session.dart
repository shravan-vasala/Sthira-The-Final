import 'package:isar/isar.dart';

part 'workout_session.g.dart';

@collection
class WorkoutSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String key;
  final String jsonStr;

  WorkoutSession({required this.key, required this.jsonStr});
}
