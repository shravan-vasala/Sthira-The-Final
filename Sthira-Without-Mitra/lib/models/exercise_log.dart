import 'package:isar/isar.dart';

part 'exercise_log.g.dart';

@collection
class ExerciseLog {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('instanceId')], unique: true, replace: true)
  final String date;
  final String instanceId;
  final String exerciseName;
  final List<SetLog> sets;

  ExerciseLog({
    required this.date,
    required this.instanceId,
    required this.exerciseName,
    required this.sets,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      date: json['date'] as String,
      instanceId:
          json['instanceId'] as String? ?? json['exerciseName'] as String,
      exerciseName: json['exerciseName'] as String,
      sets:
          (json['sets'] as List?)
              ?.map((s) => SetLog.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'instanceId': instanceId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  double get maxWeight => sets.isEmpty
      ? 0
      : sets.map((s) => s.weight ?? 0.0).reduce((a, b) => a > b ? a : b);

  int get totalReps => sets.fold(0, (sum, s) => sum + (s.reps ?? 0));

  double get totalVolume =>
      sets.fold(0.0, (sum, s) => sum + ((s.weight ?? 0.0) * (s.reps ?? 0)));

  @ignore
  int get totalDurationSeconds =>
      sets.fold(0, (sum, set) => sum + (set.durationSeconds ?? 0));

  String get key => '${date}_$instanceId';
}

@embedded
class SetLog {
  int? setNumber;
  int? reps;
  double? weight;
  int? durationSeconds;

  SetLog({this.setNumber, this.reps, this.weight = 0, this.durationSeconds});

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      setNumber: json['setNumber'] as int?,
      reps: json['reps'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
  };
}
