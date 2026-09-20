import 'dart:convert';
import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  final String name;

  /// Display name for the AI / notes coach (e.g. "Shravan"). Empty → generic "Coach".
  final String coachName;
  final String? photoPath;
  final double? height; // in cm
  final double? targetWeight; // in kg
  final bool useKg;
  final int targetCalories;
  final String? activeWorkoutPlan;
  final String? activeMealPlan;
  final String? primaryGoal;
  final double? currentWeight; // in kg
  final int? age;
  final String? gender; // 'M' or 'F'
  final String? activityLevel;

  @ignore
  final List<Map<String, dynamic>> customHabits;
  @ignore
  final List<Map<String, dynamic>> customMealSlots;

  @ignore
  final String? geminiApiKey;

  String get isarCustomHabits => jsonEncode(customHabits);
  set isarCustomHabits(String json) {
    customHabits.clear();
    customHabits.addAll(
      (jsonDecode(json) as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  String get isarCustomMealSlots => jsonEncode(customMealSlots);
  set isarCustomMealSlots(String json) {
    customMealSlots.clear();
    customMealSlots.addAll(
      (jsonDecode(json) as List).map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  final bool restTimerSound;
  final bool restTimerVibration;
  final bool restTimerNotification;
  final int targetProteinG;
  final int targetCarbsG;
  final int targetFatG;
  final DateTime? planStartDate;
  final bool screenTimeEnabled;

  UserProfile({
    this.name = '',
    this.coachName = '',
    this.photoPath,
    this.height,
    this.targetWeight,
    this.useKg = true,
    this.targetCalories = 1250,
    this.activeWorkoutPlan,
    this.activeMealPlan,
    this.primaryGoal,
    this.currentWeight,
    this.age,
    this.gender,
    this.activityLevel,
    List<Map<String, dynamic>>? customHabits,
    List<Map<String, dynamic>>? customMealSlots,
    this.geminiApiKey,
    this.restTimerSound = true,
    this.restTimerVibration = true,
    this.restTimerNotification = true,
    this.targetProteinG = 85,
    this.targetCarbsG = 135,
    this.targetFatG = 40,
    this.planStartDate,
    this.screenTimeEnabled = false,
  }) : customHabits = customHabits ?? [],
       customMealSlots =
           customMealSlots ??
           [
             {
               'id': 'breakfast',
               'name': 'Breakfast',
               'emoji': 'breakfast',
               'isDefault': true,
             },
             {
               'id': 'lunch',
               'name': 'Lunch',
               'emoji': 'lunch',
               'isDefault': true,
             },
             {
               'id': 'snack',
               'name': 'Snack',
               'emoji': 'snack',
               'isDefault': true,
             },
             {
               'id': 'dinner',
               'name': 'Dinner',
               'emoji': 'dinner',
               'isDefault': true,
             },
           ];

  /// Title shown on Home coach notes (e.g. "Coach Shravan").
  String get coachDisplayName {
    final n = coachName.trim();
    if (n.isEmpty) return 'Coach';
    if (n.toLowerCase().startsWith('coach ')) return n;
    return 'Coach $n';
  }

  double get heightInMeters => (height ?? 153.0) / 100;

  double? computeBmi(double? weight) {
    if (weight == null || height == null || height! <= 0) return null;
    return weight / (heightInMeters * heightInMeters);
  }

  String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  double convertWeight(double kg) {
    return useKg ? kg : kg * 2.20462;
  }

  String get weightUnit => useKg ? 'kg' : 'lb';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      coachName: json['coachName'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      useKg: json['useKg'] as bool? ?? true,
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 1250,
      activeWorkoutPlan: json['activeWorkoutPlan'] as String?,
      activeMealPlan: json['activeMealPlan'] as String?,
      primaryGoal: json['primaryGoal'] as String?,
      currentWeight: (json['currentWeight'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      activityLevel: json['activityLevel'] as String?,
      customHabits:
          (json['customHabits'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [],
      customMealSlots:
          (json['customMealSlots'] as List?)
              ?.map((h) => Map<String, dynamic>.from(h as Map))
              .toList() ??
          [
            {
              'id': 'breakfast',
              'name': 'Breakfast',
              'emoji': 'breakfast',
              'isDefault': true,
            },
            {
              'id': 'lunch',
              'name': 'Lunch',
              'emoji': 'lunch',
              'isDefault': true,
            },
            {
              'id': 'snack',
              'name': 'Snack',
              'emoji': 'snack',
              'isDefault': true,
            },
            {
              'id': 'dinner',
              'name': 'Dinner',
              'emoji': 'dinner',
              'isDefault': true,
            },
          ],
      restTimerSound: json['restTimerSound'] as bool? ?? true,
      restTimerVibration: json['restTimerVibration'] as bool? ?? true,
      restTimerNotification: json['restTimerNotification'] as bool? ?? true,
      targetProteinG: (json['targetProteinG'] as num?)?.toInt() ?? 85,
      targetCarbsG: (json['targetCarbsG'] as num?)?.toInt() ?? 135,
      targetFatG: (json['targetFatG'] as num?)?.toInt() ?? 40,
      planStartDate: json['planStartDate'] != null
          ? DateTime.parse(json['planStartDate'] as String)
          : null,
      screenTimeEnabled: json['screenTimeEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'coachName': coachName,
    if (photoPath != null) 'photoPath': photoPath,
    if (height != null) 'height': height,
    if (targetWeight != null) 'targetWeight': targetWeight,
    'useKg': useKg,
    'targetCalories': targetCalories,
    if (activeWorkoutPlan != null) 'activeWorkoutPlan': activeWorkoutPlan,
    if (activeMealPlan != null) 'activeMealPlan': activeMealPlan,
    if (primaryGoal != null) 'primaryGoal': primaryGoal,
    if (currentWeight != null) 'currentWeight': currentWeight,
    if (age != null) 'age': age,
    if (gender != null) 'gender': gender,
    if (activityLevel != null) 'activityLevel': activityLevel,
    'customHabits': customHabits,
    'customMealSlots': customMealSlots,
    'restTimerSound': restTimerSound,
    'restTimerVibration': restTimerVibration,
    'restTimerNotification': restTimerNotification,
    'targetProteinG': targetProteinG,
    'targetCarbsG': targetCarbsG,
    'targetFatG': targetFatG,
    if (planStartDate != null)
      'planStartDate': planStartDate!.toIso8601String(),
    'screenTimeEnabled': screenTimeEnabled,
  };

  UserProfile copyWith({
    String? name,
    String? coachName,
    String? photoPath,
    double? height,
    double? targetWeight,
    bool? useKg,
    int? targetCalories,
    String? activeWorkoutPlan,
    String? activeMealPlan,
    String? primaryGoal,
    double? currentWeight,
    int? age,
    String? gender,
    String? activityLevel,
    List<Map<String, dynamic>>? customHabits,
    List<Map<String, dynamic>>? customMealSlots,
    String? geminiApiKey,
    bool? restTimerSound,
    bool? restTimerVibration,
    bool? restTimerNotification,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
    DateTime? planStartDate,
    bool? screenTimeEnabled,
    bool clearPhoto = false,
    bool clearPlanStart = false,
    bool clearGeminiApiKey = false,
    bool clearTargetWeight = false,
    bool clearCurrentWeight = false,
    bool clearHeight = false,
  }) {
    final updated = UserProfile(
      name: name ?? this.name,
      coachName: coachName ?? this.coachName,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      height: clearHeight ? null : (height ?? this.height),
      targetWeight: clearTargetWeight
          ? null
          : (targetWeight ?? this.targetWeight),
      useKg: useKg ?? this.useKg,
      targetCalories: targetCalories ?? this.targetCalories,
      activeWorkoutPlan: activeWorkoutPlan ?? this.activeWorkoutPlan,
      activeMealPlan: activeMealPlan ?? this.activeMealPlan,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      currentWeight: clearCurrentWeight
          ? null
          : (currentWeight ?? this.currentWeight),
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      customHabits: customHabits ?? this.customHabits,
      customMealSlots: customMealSlots ?? this.customMealSlots,
      geminiApiKey: clearGeminiApiKey
          ? null
          : (geminiApiKey ?? this.geminiApiKey),
      restTimerSound: restTimerSound ?? this.restTimerSound,
      restTimerVibration: restTimerVibration ?? this.restTimerVibration,
      restTimerNotification:
          restTimerNotification ?? this.restTimerNotification,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      targetFatG: targetFatG ?? this.targetFatG,
      planStartDate: clearPlanStart
          ? null
          : (planStartDate ?? this.planStartDate),
      screenTimeEnabled: screenTimeEnabled ?? this.screenTimeEnabled,
    );
    updated.id = id;
    return updated;
  }
}
