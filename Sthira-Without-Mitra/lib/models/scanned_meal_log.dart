import 'package:isar/isar.dart';

part 'scanned_meal_log.g.dart';

@collection
class ScannedMealLog {
  Id idInternal = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  final String date; // yyyy-MM-dd
  final String photoPath;
  final String mealType; // breakfast, lunch, snack, dinner
  final String foodName;
  final int estimatedCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double portionMultiplier;
  final String timestamp;

  ScannedMealLog({
    required this.id,
    required this.date,
    required this.photoPath,
    required this.mealType,
    required this.foodName,
    required this.estimatedCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.portionMultiplier = 1.0,
    required this.timestamp,
  });

  int get totalCalories => (estimatedCalories * portionMultiplier).round();
  double get totalProtein => (proteinGrams * portionMultiplier);
  double get totalCarbs => (carbsGrams * portionMultiplier);
  double get totalFat => (fatGrams * portionMultiplier);

  factory ScannedMealLog.fromJson(Map<String, dynamic> json) {
    return ScannedMealLog(
      id: json['id'] as String,
      date: json['date'] as String,
      photoPath: json['photoPath'] as String,
      mealType: json['mealType'] as String? ?? 'lunch',
      foodName: json['foodName'] as String,
      estimatedCalories: json['estimatedCalories'] as int,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0.0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 0.0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 0.0,
      portionMultiplier: (json['portionMultiplier'] as num?)?.toDouble() ?? 1.0,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'photoPath': photoPath,
    'mealType': mealType,
    'foodName': foodName,
    'estimatedCalories': estimatedCalories,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
    'portionMultiplier': portionMultiplier,
    'timestamp': timestamp,
  };
}
