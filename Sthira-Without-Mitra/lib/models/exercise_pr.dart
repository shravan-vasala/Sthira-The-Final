import 'package:isar/isar.dart';

part 'exercise_pr.g.dart';

@collection
class ExercisePr {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String exerciseName;
  final double maxWeight;
  final int maxWeightReps; // Reps performed at max weight
  final int maxReps;
  final double maxRepsWeight; // Weight performed at max reps
  final double estimated1RM;
  final double maxVolume;

  ExercisePr({
    required this.exerciseName,
    this.maxWeight = 0.0,
    this.maxWeightReps = 0,
    this.maxReps = 0,
    this.maxRepsWeight = 0.0,
    this.estimated1RM = 0.0,
    this.maxVolume = 0.0,
  });

  factory ExercisePr.fromJson(Map<String, dynamic> json) {
    return ExercisePr(
      exerciseName: json['exerciseName'] as String,
      maxWeight: (json['maxWeight'] as num?)?.toDouble() ?? 0.0,
      maxWeightReps: json['maxWeightReps'] as int? ?? 0,
      maxReps: json['maxReps'] as int? ?? 0,
      maxRepsWeight: (json['maxRepsWeight'] as num?)?.toDouble() ?? 0.0,
      estimated1RM: (json['estimated1RM'] as num?)?.toDouble() ?? 0.0,
      maxVolume: (json['maxVolume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'maxWeight': maxWeight,
    'maxWeightReps': maxWeightReps,
    'maxReps': maxReps,
    'maxRepsWeight': maxRepsWeight,
    'estimated1RM': estimated1RM,
    'maxVolume': maxVolume,
  };

  ExercisePr copyWith({
    String? exerciseName,
    double? maxWeight,
    int? maxWeightReps,
    int? maxReps,
    double? maxRepsWeight,
    double? estimated1RM,
    double? maxVolume,
  }) {
    return ExercisePr(
      exerciseName: exerciseName ?? this.exerciseName,
      maxWeight: maxWeight ?? this.maxWeight,
      maxWeightReps: maxWeightReps ?? this.maxWeightReps,
      maxReps: maxReps ?? this.maxReps,
      maxRepsWeight: maxRepsWeight ?? this.maxRepsWeight,
      estimated1RM: estimated1RM ?? this.estimated1RM,
      maxVolume: maxVolume ?? this.maxVolume,
    );
  }
}
