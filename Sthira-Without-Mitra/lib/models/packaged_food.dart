import 'food_nutrition.dart';

/// Nutrition is recorded exactly in the basis printed on the package.
enum NutritionBasis { per100g, per100ml, perServing }

enum FoodQuantityUnit { grams, millilitres }

enum PackagedFoodSource { openFoodFacts, manual }

/// An immutable label snapshot. Missing nutrients remain unknown, never zero.
class PackagedFood {
  const PackagedFood({
    required this.barcode,
    required this.name,
    this.brand,
    this.basis,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.packageQuantity,
    this.packageUnit,
    this.servingQuantity,
    this.servingUnit,
    required this.source,
  });

  final String barcode;
  final String name;
  final String? brand;
  final NutritionBasis? basis;
  final double? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? packageQuantity;
  final FoodQuantityUnit? packageUnit;
  final double? servingQuantity;
  final FoodQuantityUnit? servingUnit;
  final PackagedFoodSource source;

  bool get hasCompleteNutrition =>
      basis != null &&
      [
        kcal,
        proteinG,
        carbsG,
        fatG,
      ].every((value) => value != null && value.isFinite && value >= 0);

  String get amountUnit => switch (basis) {
    NutritionBasis.per100g => 'g',
    NutritionBasis.per100ml => 'ml',
    NutritionBasis.perServing => 'servings',
    null => '',
  };

  /// A fresh object prevents mutation of a label through FoodNutrition.
  FoodNutrition? get baseNutrition => hasCompleteNutrition
      ? FoodNutrition(
          kcal: kcal!,
          proteinG: proteinG!,
          carbsG: carbsG!,
          fatG: fatG!,
        )
      : null;

  /// [amount] is grams, millilitres, or servings according to [basis].
  /// No mass/volume conversions or guessed serving weights are performed.
  FoodNutrition computeNutrition(double amount) {
    if (!hasCompleteNutrition) {
      throw const FormatException(
        'Confirm the nutrition basis and all four nutrients first.',
      );
    }
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Enter an amount greater than zero.');
    }
    final multiplier = basis == NutritionBasis.perServing
        ? amount
        : amount / 100;
    final values = [
      kcal!,
      proteinG!,
      carbsG!,
      fatG!,
    ].map((value) => value * multiplier).toList(growable: false);
    if (values.any((value) => !value.isFinite)) {
      throw const FormatException('The amount is too large.');
    }
    return FoodNutrition(
      kcal: values[0],
      proteinG: values[1],
      carbsG: values[2],
      fatG: values[3],
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'basis': basis?.name,
    'kcal': kcal,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'package_quantity': packageQuantity,
    'package_unit': packageUnit?.name,
    'serving_quantity': servingQuantity,
    'serving_unit': servingUnit?.name,
    'source': source.name,
  };

  factory PackagedFood.fromJson(Map<String, dynamic> json) {
    if (json['barcode'] is! String || json['name'] is! String) {
      throw const FormatException('Invalid packaged food identity.');
    }
    final source = _enumValue(PackagedFoodSource.values, json['source']);
    if (source == null) {
      throw const FormatException('Invalid packaged food source.');
    }
    final packageUnit = _enumValue(
      FoodQuantityUnit.values,
      json['package_unit'],
    );
    final servingUnit = _enumValue(
      FoodQuantityUnit.values,
      json['serving_unit'],
    );
    final packageQuantity = _positive(json['package_quantity']);
    final servingQuantity = _positive(json['serving_quantity']);
    return PackagedFood(
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] is String ? json['brand'] as String : null,
      basis: _enumValue(NutritionBasis.values, json['basis']),
      kcal: _nonNegative(json['kcal']),
      proteinG: _nonNegative(json['protein_g']),
      carbsG: _nonNegative(json['carbs_g']),
      fatG: _nonNegative(json['fat_g']),
      packageQuantity: packageUnit == null ? null : packageQuantity,
      packageUnit: packageQuantity == null ? null : packageUnit,
      servingQuantity: servingUnit == null ? null : servingQuantity,
      servingUnit: servingQuantity == null ? null : servingUnit,
      source: source,
    );
  }
}

T? _enumValue<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

double? _nonNegative(Object? value) {
  final number = value is num ? value.toDouble() : null;
  return number != null && number.isFinite && number >= 0 ? number : null;
}

double? _positive(Object? value) {
  final number = _nonNegative(value);
  return number != null && number > 0 ? number : null;
}
