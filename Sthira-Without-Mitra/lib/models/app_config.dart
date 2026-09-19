import 'package:isar/isar.dart';

part 'app_config.g.dart';

@collection
class AppConfig {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String key;
  final String value;

  AppConfig({required this.key, required this.value});
}
