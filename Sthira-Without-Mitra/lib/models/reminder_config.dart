import 'package:flutter/material.dart';
import 'dart:convert';

class ReminderConfig {
  final bool habitsEnabled;
  final TimeOfDay habitTime;

  final bool workoutsEnabled;
  final TimeOfDay workoutTime;

  final bool mealsEnabled;
  final TimeOfDay lunchTime;
  final TimeOfDay dinnerTime;

  final bool backupEnabled;
  final int backupDayOfWeek; // 1 = Monday, 7 = Sunday
  final TimeOfDay backupTime;

  final bool photosEnabled;
  final TimeOfDay photoTime;

  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;

  final bool bodyFatEnabled;

  ReminderConfig({
    this.habitsEnabled = false,
    this.habitTime = const TimeOfDay(hour: 21, minute: 0),
    this.workoutsEnabled = false,
    this.workoutTime = const TimeOfDay(hour: 7, minute: 0),
    this.mealsEnabled = false,
    this.lunchTime = const TimeOfDay(hour: 13, minute: 0),
    this.dinnerTime = const TimeOfDay(hour: 19, minute: 0),
    this.backupEnabled = false,
    this.backupDayOfWeek = DateTime.sunday,
    this.backupTime = const TimeOfDay(hour: 10, minute: 0),
    this.photosEnabled = true,
    this.photoTime = const TimeOfDay(hour: 10, minute: 0),
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.bodyFatEnabled = false,
  });

  ReminderConfig copyWith({
    bool? habitsEnabled,
    TimeOfDay? habitTime,
    bool? workoutsEnabled,
    TimeOfDay? workoutTime,
    bool? mealsEnabled,
    TimeOfDay? lunchTime,
    TimeOfDay? dinnerTime,
    bool? backupEnabled,
    int? backupDayOfWeek,
    TimeOfDay? backupTime,
    bool? photosEnabled,
    TimeOfDay? photoTime,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? bodyFatEnabled,
  }) {
    return ReminderConfig(
      habitsEnabled: habitsEnabled ?? this.habitsEnabled,
      habitTime: habitTime ?? this.habitTime,
      workoutsEnabled: workoutsEnabled ?? this.workoutsEnabled,
      workoutTime: workoutTime ?? this.workoutTime,
      mealsEnabled: mealsEnabled ?? this.mealsEnabled,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      backupDayOfWeek: backupDayOfWeek ?? this.backupDayOfWeek,
      backupTime: backupTime ?? this.backupTime,
      photosEnabled: photosEnabled ?? this.photosEnabled,
      photoTime: photoTime ?? this.photoTime,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      bodyFatEnabled: bodyFatEnabled ?? this.bodyFatEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitsEnabled': habitsEnabled,
      'habitTime': '${habitTime.hour}:${habitTime.minute}',
      'workoutsEnabled': workoutsEnabled,
      'workoutTime': '${workoutTime.hour}:${workoutTime.minute}',
      'mealsEnabled': mealsEnabled,
      'lunchTime': '${lunchTime.hour}:${lunchTime.minute}',
      'dinnerTime': '${dinnerTime.hour}:${dinnerTime.minute}',
      'backupEnabled': backupEnabled,
      'backupDayOfWeek': backupDayOfWeek,
      'backupTime': '${backupTime.hour}:${backupTime.minute}',
      'photosEnabled': photosEnabled,
      'photoTime': '${photoTime.hour}:${photoTime.minute}',
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': '${quietHoursStart.hour}:${quietHoursStart.minute}',
      'quietHoursEnd': '${quietHoursEnd.hour}:${quietHoursEnd.minute}',
      'bodyFatEnabled': bodyFatEnabled,
    };
  }

  factory ReminderConfig.fromMap(Map<String, dynamic> map) {
    TimeOfDay parseTime(dynamic timeStr, TimeOfDay defaultTime) {
      if (timeStr is! String || !timeStr.contains(':')) return defaultTime;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null ||
            hour < 0 ||
            hour > 23 ||
            minute == null ||
            minute < 0 ||
            minute > 59)
          return defaultTime;
        return TimeOfDay(hour: hour, minute: minute);
      }
      return defaultTime;
    }

    return ReminderConfig(
      habitsEnabled: map['habitsEnabled'] == true,
      habitTime: parseTime(
        map['habitTime'],
        const TimeOfDay(hour: 21, minute: 0),
      ),
      workoutsEnabled: map['workoutsEnabled'] == true,
      workoutTime: parseTime(
        map['workoutTime'],
        const TimeOfDay(hour: 7, minute: 0),
      ),
      mealsEnabled: map['mealsEnabled'] == true,
      lunchTime: parseTime(
        map['lunchTime'],
        const TimeOfDay(hour: 13, minute: 0),
      ),
      dinnerTime: parseTime(
        map['dinnerTime'],
        const TimeOfDay(hour: 19, minute: 0),
      ),
      backupEnabled: map['backupEnabled'] == true,
      backupDayOfWeek:
          map['backupDayOfWeek'] is int &&
              map['backupDayOfWeek'] >= 1 &&
              map['backupDayOfWeek'] <= 7
          ? map['backupDayOfWeek'] as int
          : DateTime.sunday,
      backupTime: parseTime(
        map['backupTime'],
        const TimeOfDay(hour: 10, minute: 0),
      ),
      photosEnabled: map['photosEnabled'] is bool
          ? map['photosEnabled'] as bool
          : true,
      photoTime: parseTime(
        map['photoTime'],
        const TimeOfDay(hour: 10, minute: 0),
      ),
      quietHoursEnabled: map['quietHoursEnabled'] == true,
      quietHoursStart: parseTime(
        map['quietHoursStart'],
        const TimeOfDay(hour: 22, minute: 0),
      ),
      quietHoursEnd: parseTime(
        map['quietHoursEnd'],
        const TimeOfDay(hour: 7, minute: 0),
      ),
      bodyFatEnabled: map['bodyFatEnabled'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReminderConfig.fromJson(String source) {
    try {
      final decoded = json.decode(source);
      return decoded is Map<String, dynamic>
          ? ReminderConfig.fromMap(decoded)
          : ReminderConfig();
    } catch (_) {
      return ReminderConfig();
    }
  }
}
