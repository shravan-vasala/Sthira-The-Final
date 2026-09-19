import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../models/user_food_log.dart';
import '../utils/food_name.dart';

import '../models/nutrition_lookup_result.dart';
import '../models/food_nutrition.dart';

class NutritionLookupService {
  final Isar? _database;
  final Isar? Function()? _databaseResolver;

  NutritionLookupService({Isar? database, Isar? Function()? databaseResolver})
    : _database = database,
      _databaseResolver = databaseResolver;

  final Map<String, NutritionLookupResult> _index = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  Future<void> load() async {
    if (_isLoaded) return;
    if (_loadFuture != null) return _loadFuture;
    _loadFuture = _doLoad().whenComplete(() => _loadFuture = null);
    return _loadFuture;
  }

  Future<void> _doLoad() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/nutrition_table.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (var item in jsonList) {
        final mapItem = item as Map<String, dynamic>;
        final result = _mapToResult(mapItem);

        final name = canonicalFoodName(mapItem['name'] as String);
        _index[name] = result;

        final aliases = List<String>.from(mapItem['aliases'] ?? []);
        for (var alias in aliases) {
          _index[canonicalFoodName(alias)] = result;
        }
      }
      _isLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load nutrition table: $e');
    }
  }

  /// Returns the matched item if found, otherwise null.
  NutritionLookupResult? match(String dishName) {
    if (!_isLoaded || dishName.trim().isEmpty) return null;

    final queryStr = canonicalFoodName(dishName);
    if (queryStr.isEmpty) return null;

    // 0. Check UserFoodLog (Personalized Local DB) first (Exact match)
    try {
      // Resolve on every match because authentication can switch databases
      // while this service remains alive. A null resolver result stays null.
      final isar = _databaseResolver != null
          ? _databaseResolver()
          : _database ??
                (Isar.instanceNames.length == 1
                    ? Isar.getInstance(Isar.instanceNames.single)
                    : null);
      if (isar != null && isar.isOpen) {
        var userFood = isar.userFoodLogs
            .where()
            .normalizedNameEqualTo(queryStr)
            .findFirstSync();
        // Older records used lowercase-only keys. Read them without changing
        // user data during lookup; new corrections use the canonical key.
        userFood ??= _legacyMatch(isar, queryStr);
        if (userFood != null) {
          return NutritionLookupResult(
            id: 'user_food_${userFood.id}',
            name: userFood.originalName,
            baseNutrition: userFood.baseNutrition,
            isPer100g: userFood.isPer100g,
            servingGrams: userFood.servingGrams,
            provenance: userFood.provenance ?? 'legacy',
            estimated: !['yours', 'verified'].contains(userFood.provenance),
          );
        }
      }
    } catch (_) {
      // Personal memory is optional; the bundled nutrition table still works.
    }

    // 1. O(1) Index lookup
    final match = _index[queryStr];
    if (match != null) {
      return match;
    }

    // Subsets are dangerous (e.g. "fried rice" matching "rice"); exact/alias only.
    return null;
  }

  NutritionLookupResult _mapToResult(Map<String, dynamic> item) {
    final per100g = item['per100g'] as Map<String, dynamic>?;
    final perServing = item['perServing'] as Map<String, dynamic>?;

    // nutrition_table.json generator uses 'per100g' specifically.
    final isPer100g = per100g != null;
    final nutSource = per100g ?? perServing ?? {};

    return NutritionLookupResult(
      id: item['id'] as String? ?? 'unknown',
      name: item['name'] as String? ?? 'Unknown',
      baseNutrition: FoodNutrition(
        kcal: (nutSource['kcal'] as num?)?.toDouble() ?? 0.0,
        proteinG: (nutSource['protein_g'] as num?)?.toDouble() ?? 0.0,
        carbsG: (nutSource['carbs_g'] as num?)?.toDouble() ?? 0.0,
        fatG: (nutSource['fat_g'] as num?)?.toDouble() ?? 0.0,
      ),
      isPer100g: isPer100g,
      servingGrams: (item['defaultPortionG'] as num?)
          ?.toDouble(), // Default serving grams in JSON
      baseQuantityUnit: item['base_quantity_unit'] as String?,
      provenance: item['estimated'] == false ? 'database' : 'database_estimate',
      estimated: item['estimated'] != false,
      preparation: item['preparation'] as String?,
    );
  }

  UserFoodLog? _legacyMatch(Isar database, String query) {
    final candidates =
        database.userFoodLogs
            .where()
            .findAllSync()
            .where((food) => canonicalFoodName(food.originalName) == query)
            .toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    for (final food in candidates) {
      if (food.provenance == 'yours' || food.provenance == 'verified')
        return food;
    }
    return candidates.isEmpty ? null : candidates.first;
  }
}
