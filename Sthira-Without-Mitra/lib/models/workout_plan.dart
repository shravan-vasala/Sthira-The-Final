import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';

part 'workout_plan.g.dart';

@collection
class WorkoutPlan {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String planName;
  final int? durationWeeks;
  final List<WorkoutWeek>? weeks;
  final List<WorkoutDay> days;

  /// 'seed' = shipped by an expert, managed by migration.
  /// 'user' = authored or forked by the user, never touched by migration.
  final String source;

  /// Seed asset version this record was created from. Null for user plans.
  final int? seedVersion;
  final String? basedOnPlanName;

  WorkoutPlan({
    required this.planName,
    this.durationWeeks,
    this.weeks,
    required this.days,
    this.source = 'user',
    this.seedVersion,
    this.basedOnPlanName,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      planName: json['planName'] as String,
      durationWeeks: json['durationWeeks'] as int?,
      weeks: json['weeks'] != null
          ? (json['weeks'] as List)
                .map((w) => WorkoutWeek.fromJson(w as Map<String, dynamic>))
                .toList()
          : null,
      days:
          (json['days'] as List?)
              ?.map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      source: json['source'] as String? ?? 'user',
      seedVersion: json['seedVersion'] as int?,
      basedOnPlanName: json['basedOnPlanName'] as String?,
    )..ensureExerciseIds();
  }

  /// Stable occurrence identities survive reloads and differ for repeated names.
  /// Explicit existing IDs are retained; only missing or duplicate IDs change.
  bool ensureExerciseIds() {
    final used = <String>{};
    var changed = false;
    void normalize(List<WorkoutDay> schedule, String week) {
      for (var d = 0; d < schedule.length; d++) {
        final day = schedule[d];
        for (var s = 0; s < day.sections.length; s++) {
          final exercises = day.sections[s].exercises;
          for (var e = 0; e < exercises.length; e++) {
            final exercise = exercises[e];
            final current = exercise.instanceId;
            if (current != null &&
                current.trim().isNotEmpty &&
                used.add(current))
              continue;
            final identity = jsonEncode([
              planName,
              week,
              day.dayId,
              d,
              s,
              e,
              exercise.name,
            ]);
            var suffix = 0;
            String candidate;
            do {
              candidate =
                  'workout-v1-${sha256.convert(utf8.encode('$identity:$suffix'))}';
              suffix++;
            } while (!used.add(candidate));
            exercise.instanceId = candidate;
            changed = true;
          }
        }
      }
    }

    normalize(days, 'repeating');
    for (var i = 0; i < (weeks?.length ?? 0); i++) {
      normalize(weeks![i].days, 'week-${i + 1}');
    }
    return changed;
  }

  Map<String, dynamic> toJson() => {
    'planName': planName,
    if (durationWeeks != null) 'durationWeeks': durationWeeks,
    if (weeks != null) 'weeks': weeks!.map((w) => w.toJson()).toList(),
    'days': days.map((d) => d.toJson()).toList(),
    'source': source,
    if (seedVersion != null) 'seedVersion': seedVersion,
    if (basedOnPlanName != null) 'basedOnPlanName': basedOnPlanName,
  };

  WorkoutPlan copyWith({
    String? planName,
    int? durationWeeks,
    List<WorkoutWeek>? weeks,
    List<WorkoutDay>? days,
    String? source,
    int? seedVersion,
    String? basedOnPlanName,
  }) {
    return WorkoutPlan(
      planName: planName ?? this.planName,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      weeks: weeks ?? this.weeks,
      days: days ?? this.days,
      source: source ?? this.source,
      seedVersion: seedVersion ?? this.seedVersion,
      basedOnPlanName: basedOnPlanName ?? this.basedOnPlanName,
    );
  }
}

@embedded
class WorkoutWeek {
  int? weekNumber;
  List<WorkoutDay> days;

  WorkoutWeek({this.weekNumber, this.days = const []});

  factory WorkoutWeek.fromJson(Map<String, dynamic> json) {
    return WorkoutWeek(
      weekNumber: json['weekNumber'] as int?,
      days:
          (json['days'] as List?)
              ?.map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (weekNumber != null) 'weekNumber': weekNumber,
    'days': days.map((d) => d.toJson()).toList(),
  };
}

@embedded
class WorkoutDay {
  String? dayId;
  String? label;
  List<WorkoutSection> sections;

  WorkoutDay({this.dayId, this.label, this.sections = const []});

  int? get weekday {
    if (dayId == null) return null;
    switch (dayId?.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dayId: json['dayId'] as String,
      label: json['label'] as String?,
      sections: (json['sections'] as List)
          .map((s) => WorkoutSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dayId': dayId,
    if (label != null) 'label': label,
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}

@embedded
class WorkoutSection {
  String? title;
  List<Exercise> exercises;

  WorkoutSection({this.title, this.exercises = const []});

  factory WorkoutSection.fromJson(Map<String, dynamic> json) {
    return WorkoutSection(
      title: json['title'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

@embedded
class Exercise {
  String? instanceId;

  String? name;
  String? displayName;
  String? youtubeUrl;
  List<String> reps;
  String note;
  String sideInfo;
  int restSecondsAfterSet;
  double? weightKg;
  int? durationSeconds;

  Exercise({
    this.name,
    this.displayName,
    this.youtubeUrl,
    this.reps = const [],
    this.note = '',
    this.sideInfo = 'None',
    this.restSecondsAfterSet = 0,
    this.weightKg,
    this.durationSeconds,
  });

  String? get youtubeVideoId {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return null;
    final uri = Uri.tryParse(youtubeUrl!);
    if (uri == null) return null;

    // Handle youtu.be/ID format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // Handle youtube.com/watch?v=ID or youtube.com/shorts/ID format
    if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts') {
        if (uri.pathSegments.length > 1) {
          return uri.pathSegments[1];
        }
      }
      return uri.queryParameters['v'];
    }
    return null;
  }

  String get thumbnailUrl {
    final id = youtubeVideoId;
    if (id == null || id.isEmpty || id == 'XXXX') {
      return '';
    }
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  String get repsDisplay {
    if (durationSeconds != null && durationSeconds! > 0) {
      return '${durationSeconds}s';
    }
    if (reps.isEmpty) return '';
    final bool allSame = reps.every((r) => r == reps.first);
    if (allSame && reps.length > 1) {
      return '${reps.length} × ${reps.first}';
    }
    if (reps.length == 1) return reps.first;
    return reps.join(', ');
  }

  int get setCount => reps.length;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      displayName: json['displayName'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      reps: (json['reps'] as List? ?? const [])
          .map((r) => r.toString())
          .toList(),
      note: json['note'] as String? ?? '',
      sideInfo: json['sideInfo'] as String? ?? 'None',
      restSecondsAfterSet: json['restSecondsAfterSet'] as int? ?? 0,
      weightKg: json['weightKg'] != null
          ? (json['weightKg'] as num).toDouble()
          : null,
      durationSeconds: json['durationSeconds'] as int?,
    )..instanceId = json['instanceId'] as String?;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (displayName != null) 'displayName': displayName,
    if (youtubeUrl != null && youtubeUrl!.isNotEmpty) 'youtubeUrl': youtubeUrl,
    'reps': reps,
    'note': note,
    'sideInfo': sideInfo,
    'restSecondsAfterSet': restSecondsAfterSet,
    if (weightKg != null) 'weightKg': weightKg,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (instanceId != null) 'instanceId': instanceId,
  };
}
