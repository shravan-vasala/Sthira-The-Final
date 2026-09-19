import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/packaged_food.dart';

class SavedPackagedFood {
  const SavedPackagedFood({
    required this.food,
    required this.savedAt,
    this.lastAmount,
  });
  final PackagedFood food;
  final DateTime savedAt;
  final double? lastAmount;
}

/// Device-local shortcuts, scoped to the current account and product market.
/// Meal logs keep their own nutrition snapshot and never read totals from here.
class BarcodeFoodStore {
  BarcodeFoodStore(
    this.preferences, {
    required String accountId,
    String market = 'in',
  }) : _key = 'barcode_foods_v1_${Uri.encodeComponent(accountId)}_$market';

  final SharedPreferences preferences;
  final String _key;
  static const maximumProducts = 60;

  List<SavedPackagedFood> get recent {
    try {
      final raw = preferences.getString(_key);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final result = <SavedPackagedFood>[];
      for (final entry in decoded) {
        try {
          final map = Map<String, dynamic>.from(entry as Map);
          final food = PackagedFood.fromJson(
            Map<String, dynamic>.from(map['food'] as Map),
          );
          if (!food.hasCompleteNutrition ||
              food.name.trim().isEmpty ||
              _identity(food.barcode) == null) {
            continue;
          }
          final value = map['last_amount'];
          final amount = value is num ? value.toDouble() : null;
          result.add(
            SavedPackagedFood(
              food: food,
              savedAt: DateTime.parse(map['saved_at'] as String),
              lastAmount: amount != null && amount.isFinite && amount > 0
                  ? amount
                  : null,
            ),
          );
        } on Object {
          // One old/corrupt shortcut must not hide every other saved food.
        }
      }
      result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      final seen = <String>{};
      return result
          .where((entry) => seen.add(_identity(entry.food.barcode)!))
          .take(maximumProducts)
          .toList(growable: false);
    } on Object {
      return [];
    }
  }

  SavedPackagedFood? find(String barcode) {
    final identity = _identity(barcode);
    if (identity == null) return null;
    for (final entry in recent) {
      if (_identity(entry.food.barcode) == identity) return entry;
    }
    return null;
  }

  Future<void> remember(PackagedFood food, double amount) async {
    if (_identity(food.barcode) == null || food.name.trim().isEmpty) {
      throw const FormatException(
        'Confirm the product barcode and name first.',
      );
    }
    food.computeNutrition(amount); // Never cache unresolved/invalid label data.
    final entries = recent.where(
      (entry) => _identity(entry.food.barcode) != _identity(food.barcode),
    );
    final items = [
      SavedPackagedFood(
        food: food,
        lastAmount: amount,
        savedAt: DateTime.now(),
      ),
      ...entries,
    ].take(maximumProducts);
    final saved = await preferences.setString(
      _key,
      jsonEncode(
        items
            .map(
              (entry) => {
                'food': entry.food.toJson(),
                'last_amount': entry.lastAmount,
                'saved_at': entry.savedAt.toIso8601String(),
              },
            )
            .toList(),
      ),
    );
    if (!saved) {
      throw StateError('Could not remember this product on the device.');
    }
  }

  // GTIN-8, UPC-A, EAN-13 and zero-padded GTIN-14 preserve one identity.
  // A non-zero GTIN-14 package indicator remains a distinct product.
  String? _identity(String barcode) {
    final code = barcode.trim();
    if (!RegExp(r'^(?:[0-9]{8}|[0-9]{12,14})$').hasMatch(code)) return null;
    return code.padLeft(14, '0');
  }
}
