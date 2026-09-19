import 'package:isar/isar.dart';

part 'meal_plan.g.dart';

@collection
class MealPlan {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String planName;
  final List<Meal> meals;
  final int totalCalories;

  /// 'seed' = expert-suggested bundled content, managed by migration.
  /// 'user' = authored or forked by the user, never touched by migration.
  final String source;
  final String? basedOnPlanName;

  /// Seed asset version this record was created from. Null for user plans.
  final int? seedVersion;

  MealPlan({
    required this.planName,
    required this.meals,
    required this.totalCalories,
    this.source = 'user',
    this.basedOnPlanName,
    this.seedVersion,
  });

  int get completedMeals => meals.where((m) => m.isCompleted).length;
  int get completedCalories =>
      meals.where((m) => m.isCompleted).fold(0, (sum, m) => sum + m.calories);

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final meals = (json['meals'] as List)
        .map((m) => Meal.fromJson(m as Map<String, dynamic>))
        .toList();
    return MealPlan(
      planName: json['planName'] as String,
      meals: meals,
      totalCalories:
          json['totalCalories'] as int? ??
          meals.fold(0, (sum, m) => sum + m.calories),
      source: json['source'] as String? ?? 'user',
      basedOnPlanName: json['basedOnPlanName'] as String?,
      seedVersion: json['seedVersion'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'planName': planName,
    'meals': meals.map((m) => m.toJson()).toList(),
    'totalCalories': totalCalories,
    'source': source,
    if (basedOnPlanName != null) 'basedOnPlanName': basedOnPlanName,
    if (seedVersion != null) 'seedVersion': seedVersion,
  };

  MealPlan copyWith({
    String? planName,
    List<Meal>? meals,
    int? totalCalories,
    String? source,
    int? seedVersion,
    String? basedOnPlanName,
  }) {
    return MealPlan(
      planName: planName ?? this.planName,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      source: source ?? this.source,
      basedOnPlanName: basedOnPlanName ?? this.basedOnPlanName,
      seedVersion: seedVersion ?? this.seedVersion,
    );
  }
}

@embedded
class Meal {
  String? name;
  String? type; // breakfast, lunch, snack, dinner
  List<MealItem> items;
  int calories;
  bool isCompleted;

  /// Authored plan guidance, preserved verbatim when importing or displaying.
  List<String> suggestions;

  Meal({
    this.name,
    this.type,
    this.items = const [],
    this.calories = 0,
    this.isCompleted = false,
    this.suggestions = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] as String,
      type: json['type'] as String,
      items:
          (json['items'] as List?)
              ?.map((i) => MealItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      calories: json['calories'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'items': items.map((i) => i.toJson()).toList(),
    'calories': calories,
    'isCompleted': isCompleted,
    'suggestions': suggestions,
  };

  Meal copyWith({bool? isCompleted}) {
    return Meal(
      name: name,
      type: type,
      items: items,
      calories: calories,
      isCompleted: isCompleted ?? this.isCompleted,
      suggestions: suggestions,
    );
  }

  String get icon {
    switch (type) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'snack':
        return '🍎';
      case 'dinner':
        return '🌙';
      default:
        return '🍽️';
    }
  }
}

@embedded
class MealItem {
  String? name;
  String? quantity;
  int? calories;
  double? proteinG;
  double? carbsG;
  double? fatG;

  MealItem({
    this.name,
    this.quantity,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  @ignore
  bool get hasCompleteMacros =>
      proteinG != null && carbsG != null && fatG != null;

  /// A template choice or quantity range is not an actual logged portion.
  @ignore
  bool get needsFoodOrPortionChoice {
    final food = name?.trim() ?? '';
    final amount = quantity?.trim() ?? '';
    return food.isEmpty ||
        amount.isEmpty ||
        RegExp(r'\bor\b|/', caseSensitive: false).hasMatch(food) ||
        RegExp(
          r'\bor\b|/|\d\s*(?:-|\u2013|to)\s*\d',
          caseSensitive: false,
        ).hasMatch(amount) ||
        !RegExp(r'^\d+(?:\.\d+)?\s*\S').hasMatch(amount);
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    double? number(String camel, String snake) {
      final raw = json[camel] ?? json[snake];
      if (raw == null) return null;
      if (raw is! num || !raw.isFinite || raw < 0) {
        throw FormatException('$camel must be a finite nonnegative number.');
      }
      return raw.toDouble();
    }

    final rawCalories = number('calories', 'kcal');
    if (rawCalories != null && rawCalories != rawCalories.roundToDouble()) {
      throw const FormatException('calories must be a whole number.');
    }
    final quantity = json['quantity'] ?? json['portion'];
    if (quantity != null && quantity is! String) {
      throw const FormatException('quantity must be text.');
    }
    return MealItem(
      name: json['name'] as String,
      quantity: quantity as String? ?? '',
      calories: rawCalories?.toInt(),
      proteinG: number('proteinG', 'protein_g'),
      carbsG: number('carbsG', 'carbs_g'),
      fatG: number('fatG', 'fat_g'),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    if (calories != null) 'calories': calories,
    if (proteinG != null) 'proteinG': proteinG,
    if (carbsG != null) 'carbsG': carbsG,
    if (fatG != null) 'fatG': fatG,
  };
}
