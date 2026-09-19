import 'package:isar/isar.dart';

part 'daily_log.g.dart';

@collection
class DailyLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String date; // yyyy-MM-dd
  final double? weight;
  final int? steps;
  final String? stepsSource; // 'healthConnect' | 'manual' | null
  final double? sleepHours;
  final String? sleepSource; // 'healthConnect' | 'manual' | null
  final double? bodyFat;
  final String? workoutStatus; // 'completed', 'partial', 'skipped', null
  final String? workoutDayId;
  final int? waterMl;
  final int? screenTimeMinutes;
  final DateTime? updatedAt;

  // Daily check-in
  final String? dayFeeling;
  final String? dayNote;
  final DateTime? checkInUpdatedAt;

  // Preserve legacy boolean getter
  bool get workoutCompleted => workoutStatus == 'completed';

  DailyLog({
    required this.date,
    this.weight,
    this.steps,
    this.stepsSource,
    this.sleepHours,
    this.sleepSource,
    this.bodyFat,
    this.workoutStatus,
    this.workoutDayId,
    this.waterMl,
    this.screenTimeMinutes,
    this.updatedAt,
    this.dayFeeling,
    this.dayNote,
    this.checkInUpdatedAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: json['date'] as String,
      weight: (json['weight'] as num?)?.toDouble(),
      steps: json['steps'] as int?,
      stepsSource: json['stepsSource'] as String?,
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepSource: json['sleepSource'] as String?,
      bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      workoutStatus:
          json['workoutStatus'] as String? ??
          ((json['workoutCompleted'] as bool? ?? false) ? 'completed' : null),
      workoutDayId: json['workoutDayId'] as String?,
      waterMl: json['waterMl'] as int?,
      screenTimeMinutes: json['screenTimeMinutes'] as int?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      dayFeeling: json['dayFeeling'] as String?,
      dayNote: json['dayNote'] as String?,
      checkInUpdatedAt: json['checkInUpdatedAt'] != null
          ? DateTime.tryParse(json['checkInUpdatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    if (weight != null) 'weight': weight,
    if (steps != null) 'steps': steps,
    if (stepsSource != null) 'stepsSource': stepsSource,
    if (sleepHours != null) 'sleepHours': sleepHours,
    if (sleepSource != null) 'sleepSource': sleepSource,
    if (bodyFat != null) 'bodyFat': bodyFat,
    if (workoutStatus != null) 'workoutStatus': workoutStatus,
    if (workoutDayId != null) 'workoutDayId': workoutDayId,
    if (waterMl != null) 'waterMl': waterMl,
    if (screenTimeMinutes != null) 'screenTimeMinutes': screenTimeMinutes,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (dayFeeling != null) 'dayFeeling': dayFeeling,
    if (dayNote != null) 'dayNote': dayNote,
    if (checkInUpdatedAt != null)
      'checkInUpdatedAt': checkInUpdatedAt!.toIso8601String(),
  };

  DailyLog copyWith({
    double? weight,
    int? steps,
    String? stepsSource,
    double? sleepHours,
    String? sleepSource,
    double? bodyFat,
    String? workoutStatus,
    String? workoutDayId,
    int? waterMl,
    int? screenTimeMinutes,
    DateTime? updatedAt,
    String? dayFeeling,
    String? dayNote,
    DateTime? checkInUpdatedAt,
  }) {
    return DailyLog(
      date: date,
      weight: weight ?? this.weight,
      steps: steps ?? this.steps,
      stepsSource: stepsSource ?? this.stepsSource,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepSource: sleepSource ?? this.sleepSource,
      bodyFat: bodyFat ?? this.bodyFat,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      waterMl: waterMl ?? this.waterMl,
      screenTimeMinutes: screenTimeMinutes ?? this.screenTimeMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      dayFeeling: dayFeeling ?? this.dayFeeling,
      dayNote: dayNote ?? this.dayNote,
      checkInUpdatedAt: checkInUpdatedAt ?? this.checkInUpdatedAt,
    );
  }

  DailyLog clearCheckIn() {
    return DailyLog(
      date: date,
      weight: weight,
      steps: steps,
      stepsSource: stepsSource,
      sleepHours: sleepHours,
      sleepSource: sleepSource,
      bodyFat: bodyFat,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: waterMl,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: null,
      dayNote: null,
      checkInUpdatedAt: null,
    );
  }

  DailyLog clearWeight() {
    return DailyLog(
      date: date,
      weight: null,
      steps: steps,
      stepsSource: stepsSource,
      sleepHours: sleepHours,
      sleepSource: sleepSource,
      bodyFat: bodyFat,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: waterMl,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: dayFeeling,
      dayNote: dayNote,
      checkInUpdatedAt: checkInUpdatedAt,
    );
  }

  DailyLog clearSteps() {
    return DailyLog(
      date: date,
      weight: weight,
      steps: null,
      stepsSource: null,
      sleepHours: sleepHours,
      sleepSource: sleepSource,
      bodyFat: bodyFat,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: waterMl,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: dayFeeling,
      dayNote: dayNote,
      checkInUpdatedAt: checkInUpdatedAt,
    );
  }

  DailyLog clearSleep() {
    return DailyLog(
      date: date,
      weight: weight,
      steps: steps,
      stepsSource: stepsSource,
      sleepHours: null,
      sleepSource: null,
      bodyFat: bodyFat,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: waterMl,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: dayFeeling,
      dayNote: dayNote,
      checkInUpdatedAt: checkInUpdatedAt,
    );
  }

  DailyLog clearBodyFat() {
    return DailyLog(
      date: date,
      weight: weight,
      steps: steps,
      stepsSource: stepsSource,
      sleepHours: sleepHours,
      sleepSource: sleepSource,
      bodyFat: null,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: waterMl,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: dayFeeling,
      dayNote: dayNote,
      checkInUpdatedAt: checkInUpdatedAt,
    );
  }

  DailyLog clearWater() {
    return DailyLog(
      date: date,
      weight: weight,
      steps: steps,
      stepsSource: stepsSource,
      sleepHours: sleepHours,
      sleepSource: sleepSource,
      bodyFat: bodyFat,
      workoutStatus: workoutStatus,
      workoutDayId: workoutDayId,
      waterMl: null,
      screenTimeMinutes: screenTimeMinutes,
      updatedAt: updatedAt,
      dayFeeling: dayFeeling,
      dayNote: dayNote,
      checkInUpdatedAt: checkInUpdatedAt,
    );
  }

  bool get hasAnyActivity =>
      weight != null ||
      steps != null ||
      sleepHours != null ||
      workoutStatus != null ||
      screenTimeMinutes != null ||
      waterMl != null ||
      bodyFat != null ||
      (dayFeeling?.trim().isNotEmpty ?? false) ||
      (dayNote?.trim().isNotEmpty ?? false);
}
