import 'package:isar/isar.dart';
import 'food_nutrition.dart';

part 'daily_meal_log.g.dart';

@collection
class DailyMealLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String date; // yyyy-MM-dd

  DateTime? updatedAt;

  @ignore
  Map<String, MealSlotLog> customSlots;

  List<CustomSlotEntry> get isarCustomSlots => customSlots.entries
      .map(
        (e) => CustomSlotEntry()
          ..key = e.key
          ..value = e.value,
      )
      .toList();
  set isarCustomSlots(List<CustomSlotEntry> list) {
    customSlots = {
      for (var e in list)
        if (e.key != null && e.value != null) e.key!: e.value!,
    };
  }

  DailyMealLog({
    required this.date,
    Map<String, MealSlotLog>? customSlots,
    this.updatedAt,
  }) : customSlots = customSlots ?? {};

  int get totalCalories =>
      customSlots.values.fold(0, (sum, slot) => sum + slot.totalCalories);

  double get totalProtein =>
      customSlots.values.fold(0, (sum, slot) => sum + slot.knownProtein);

  double get totalCarbs =>
      customSlots.values.fold(0, (sum, slot) => sum + slot.knownCarbs);

  double get totalFat =>
      customSlots.values.fold(0, (sum, slot) => sum + slot.knownFat);

  /// Completeness covers the recorded foods, not whether every meal was logged.
  @ignore
  bool get hasCompleteCalories => customSlots.values
      .where((slot) => slot.isLogged)
      .every((slot) => slot.hasCompleteCalories);

  @ignore
  bool get hasCompleteMacros => customSlots.values
      .where((slot) => slot.isLogged)
      .every((slot) => slot.hasCompleteMacros);

  int get loggedSlotsCount =>
      customSlots.values.where((slot) => slot.isLogged).length;

  factory DailyMealLog.fromJson(Map<String, dynamic> json) {
    final Map<String, MealSlotLog> slots = {};

    // Legacy fields migration
    if (json['breakfast'] != null) {
      slots['breakfast'] = MealSlotLog.fromJson(
        json['breakfast'] as Map<String, dynamic>,
      );
    }
    if (json['lunch'] != null) {
      slots['lunch'] = MealSlotLog.fromJson(
        json['lunch'] as Map<String, dynamic>,
      );
    }
    if (json['snack'] != null) {
      slots['snack'] = MealSlotLog.fromJson(
        json['snack'] as Map<String, dynamic>,
      );
    }
    if (json['dinner'] != null) {
      slots['dinner'] = MealSlotLog.fromJson(
        json['dinner'] as Map<String, dynamic>,
      );
    }

    // New format
    if (json['customSlots'] != null && json['customSlots'] is Map) {
      final map = Map<String, dynamic>.from(json['customSlots'] as Map);
      for (final entry in map.entries) {
        if (entry.value is Map) {
          slots[entry.key] = MealSlotLog.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return DailyMealLog(
      date: json['date'] as String,
      customSlots: slots,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'customSlots': customSlots.map((k, v) => MapEntry(k, v.toJson())),
  };

  DailyMealLog copyWith({
    Map<String, MealSlotLog>? customSlots,
    DateTime? updatedAt,
  }) {
    return DailyMealLog(
      date: date,
      customSlots: customSlots ?? this.customSlots,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@embedded
class CustomSlotEntry {
  String? key;
  MealSlotLog? value;
}

@embedded
class MealSlotLog {
  String? name;
  String? emoji;
  String? photoPath;
  List<String> photoPaths;
  List<MealItemLog> items;
  int totalCalories;
  double totalProtein;
  double totalCarbs;
  double totalFat;
  String? confidence; // "high", "medium", "low", "planned"
  bool? caloriesComplete;
  bool? macrosComplete;

  @ignore
  bool get isLogged =>
      items.isNotEmpty ||
      photoPath != null ||
      photoPaths.isNotEmpty ||
      totalCalories > 0;

  /// Old photo-only records defaulted absent totals to zero. A picture records
  /// a meal, but does not establish zero nutrition. Existing explicit flags can
  /// still certify an intentionally recorded zero without changing stored data.
  bool get _photoWithoutNutrition =>
      (photoPath != null || photoPaths.isNotEmpty) &&
      items.isEmpty &&
      totalCalories == 0 &&
      totalProtein == 0 &&
      totalCarbs == 0 &&
      totalFat == 0;

  @ignore
  bool get hasCompleteCalories =>
      caloriesComplete != false &&
      (caloriesComplete == true || !_photoWithoutNutrition) &&
      items.every((item) => item.resolved);

  @ignore
  bool get hasCompleteMacros =>
      macrosComplete != false &&
      (macrosComplete == true || !_photoWithoutNutrition) &&
      (macrosComplete == true || confidence != 'planned') &&
      items.every((item) => item.resolved && item.macrosKnown != false);

  /// Legacy planned macros were allocated from goals, not from the food.
  /// Keep those saved values intact for export, but never use them as intake.
  bool hasKnownMacrosFor(MealItemLog item) =>
      item.hasKnownMacros &&
      (confidence != 'planned' ||
          macrosComplete == true ||
          item.macrosKnown == true ||
          (item.provenance != null &&
              item.provenance != 'expert_plan' &&
              item.provenance != 'meal_plan'));

  @ignore
  double get knownProtein => confidence != 'planned' || macrosComplete == true
      ? totalProtein
      : items
            .where(hasKnownMacrosFor)
            .fold(0.0, (sum, item) => sum + item.computedNutrition!.proteinG);
  @ignore
  double get knownCarbs => confidence != 'planned' || macrosComplete == true
      ? totalCarbs
      : items
            .where(hasKnownMacrosFor)
            .fold(0.0, (sum, item) => sum + item.computedNutrition!.carbsG);
  @ignore
  double get knownFat => confidence != 'planned' || macrosComplete == true
      ? totalFat
      : items
            .where(hasKnownMacrosFor)
            .fold(0.0, (sum, item) => sum + item.computedNutrition!.fatG);

  MealSlotLog({
    this.name,
    this.emoji,
    this.photoPath,
    this.photoPaths = const [],
    this.items = const [],
    this.totalCalories = 0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.confidence,
    this.caloriesComplete,
    this.macrosComplete,
  });

  factory MealSlotLog.fromJson(Map<String, dynamic> json) {
    return MealSlotLog(
      name: json['name'] as String?,
      emoji: json['emoji'] as String?,
      photoPath: json['photoPath'] as String?,
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      items:
          (json['items'] as List?)
              ?.map((i) => MealItemLog.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      totalCalories: json['totalCalories'] as int? ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      confidence: json['confidence'] as String?,
      caloriesComplete: json['caloriesComplete'] as bool?,
      macrosComplete: json['macrosComplete'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (emoji != null) 'emoji': emoji,
    if (photoPath != null) 'photoPath': photoPath,
    'photoPaths': photoPaths,
    'items': items.map((i) => i.toJson()).toList(),
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalCarbs': totalCarbs,
    'totalFat': totalFat,
    if (confidence != null) 'confidence': confidence,
    if (caloriesComplete != null) 'caloriesComplete': caloriesComplete,
    if (macrosComplete != null) 'macrosComplete': macrosComplete,
  };
}

@embedded
class MealItemLog {
  String? name;
  String? portion; // "2 chapatis", "100 g", etc.

  // The explicitly computed final totals (optional if unresolved)
  FoodNutrition? computedNutrition;

  // The base reference nutrition used for calculation
  FoodNutrition? baseNutrition;

  bool resolved;
  bool? macrosKnown;

  @ignore
  bool get hasKnownMacros =>
      resolved && macrosKnown != false && computedNutrition != null;
  String? provenance; // 'verified', 'estimated', 'yours'

  // Metadata about the base nutrition basis
  bool isPer100g;
  double? servingGrams;

  // Quantitative values derived from `portion`
  double? consumedGrams;

  // Optional packaged-food identity and explicit units. Legacy records keep
  // using isPer100g/servingGrams when no nutritionBasis was stored.
  String? barcode;
  String? brand;
  String? nutritionBasis; // 'per100g', 'per100ml', 'perServing'
  double? consumedMl;
  double? consumedServings;

  MealItemLog({
    this.name,
    this.portion,
    this.computedNutrition,
    this.baseNutrition,
    this.resolved = true,
    this.macrosKnown,
    this.provenance,
    bool isPer100g = false,
    this.servingGrams,
    this.consumedGrams,
    this.barcode,
    this.brand,
    this.nutritionBasis,
    this.consumedMl,
    this.consumedServings,
  }) : isPer100g = nutritionBasis == null
           ? isPer100g
           : nutritionBasis == 'per100g';

  factory MealItemLog.fromJson(Map<String, dynamic> json) {
    // Migration: If computedNutrition is missing, reconstruct it from old fields
    FoodNutrition? compNut;
    if (json['computedNutrition'] != null) {
      compNut = FoodNutrition.fromJson(
        json['computedNutrition'] as Map<String, dynamic>,
      );
    } else if (json['calories'] != null) {
      // Legacy fallback
      compNut = FoodNutrition(
        kcal: (json['calories'] as num).toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      );
    }

    FoodNutrition? baseNut;
    if (json['baseNutrition'] != null) {
      baseNut = FoodNutrition.fromJson(
        json['baseNutrition'] as Map<String, dynamic>,
      );
    }

    return MealItemLog(
      name: json['name'] as String? ?? 'Unknown',
      portion: json['portion'] as String? ?? '',
      computedNutrition: compNut,
      baseNutrition: baseNut,
      resolved: json['resolved'] as bool? ?? true,
      macrosKnown: json['macrosKnown'] as bool?,
      provenance: json['provenance'] as String?,
      isPer100g: json['is_per_100g'] as bool? ?? false,
      servingGrams: (json['serving_grams'] as num?)?.toDouble(),
      consumedGrams: (json['consumed_grams'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      brand: json['brand'] as String?,
      nutritionBasis: json['nutrition_basis'] as String?,
      consumedMl: (json['consumed_ml'] as num?)?.toDouble(),
      consumedServings: (json['consumed_servings'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'portion': portion,
    if (computedNutrition != null)
      'computedNutrition': computedNutrition!.toJson(),
    if (baseNutrition != null) 'baseNutrition': baseNutrition!.toJson(),
    'resolved': resolved,
    if (macrosKnown != null) 'macrosKnown': macrosKnown,
    if (provenance != null) 'provenance': provenance,
    'is_per_100g': isPer100g,
    if (servingGrams != null) 'serving_grams': servingGrams,
    if (consumedGrams != null) 'consumed_grams': consumedGrams,
    if (barcode != null) 'barcode': barcode,
    if (brand != null) 'brand': brand,
    if (nutritionBasis != null) 'nutrition_basis': nutritionBasis,
    if (consumedMl != null) 'consumed_ml': consumedMl,
    if (consumedServings != null) 'consumed_servings': consumedServings,

    // Write legacy fields for backward compatibility during rollback/migration
    if (computedNutrition != null) ...{
      'calories': computedNutrition!.kcal.round(),
      'protein_g': computedNutrition!.proteinG,
      'carbs_g': computedNutrition!.carbsG,
      'fat_g': computedNutrition!.fatG,
    },
  };

  /// Copies nutrition snapshots as well as metadata, so saved history does not
  /// change if a product or a pending portion is edited later.
  MealItemLog copy() => MealItemLog.fromJson(toJson())
    ..name = name
    ..portion = portion;
}
