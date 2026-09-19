import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/packaged_food.dart';

enum BarcodeLookupError {
  invalidBarcode,
  notFound,
  network,
  timeout,
  rateLimited,
  unavailable,
  invalidResponse,
}

class BarcodeLookupException implements Exception {
  const BarcodeLookupException(this.kind, this.message);

  final BarcodeLookupError kind;
  final String message;

  @override
  String toString() => message;
}

/// Read-only barcode lookup. Incomplete products are returned for label correction;
/// [PackagedFood.hasCompleteNutrition] must be true before logging them.
class BarcodeFoodService {
  BarcodeFoodService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.country = 'in',
    this.language = 'en',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;
  final String country;
  final String language;

  static const _fields =
      'code,product_name,product_name_en,brands,product_type,'
      'product_quantity,product_quantity_unit,quantity,'
      'serving_quantity,serving_quantity_unit,serving_size,'
      'nutrition_data_per,no_nutrition_data,nutriments';

  /// Preserve leading zeros. Barcode identity must never be a numeric value.
  static bool isValidBarcode(String value) =>
      RegExp(r'^(?:[0-9]{8}|[0-9]{12,14})$').hasMatch(value);

  Future<PackagedFood> lookup(String barcode) async {
    final code = barcode.trim();
    if (!isValidBarcode(code)) {
      throw const BarcodeLookupException(
        BarcodeLookupError.invalidBarcode,
        'Enter the 8, 12, 13 or 14 digits printed below the barcode.',
      );
    }
    // v3 pins the documented legacy nutriments schema. v3.5 changes that schema.
    final uri = Uri.https('world.openfoodfacts.org', '/api/v3/product/$code', {
      'fields': _fields,
      'product_type': 'food',
      'cc': country,
      'lc': language,
    });
    final abort = Completer<void>();
    final request =
        http.AbortableRequest('GET', uri, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'User-Agent':
                'Sthira/1.0.0 (https://github.com/shravan-vasala/Sthira-Without-Mitra)',
          });
    try {
      final body = await _readResponse(request).timeout(timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a product response.');
      }
      final status = decoded['status'];
      if (status == 0 || status == 'failure') {
        final result = decoded['result'];
        if (result is Map && result['id'] == 'product_not_found') {
          throw const BarcodeLookupException(
            BarcodeLookupError.notFound,
            'This product is not in Open Food Facts yet.',
          );
        }
        throw const FormatException('Product lookup failed.');
      }
      if (!const [
        'success',
        'success_with_warnings',
        'success_with_errors',
        1,
      ].contains(status)) {
        throw const FormatException('Unrecognized lookup status.');
      }
      final product = decoded['product'];
      if (product is! Map<String, dynamic> || product.isEmpty) {
        throw const FormatException('Missing product data.');
      }
      final responseCode = product['code'] ?? decoded['code'];
      if (responseCode != null &&
          (responseCode is! String ||
              !isValidBarcode(responseCode) ||
              responseCode.padLeft(14, '0') != code.padLeft(14, '0'))) {
        throw const FormatException('The response is for a different barcode.');
      }
      if (product['product_type'] != null &&
          product['product_type'] != 'food') {
        throw const BarcodeLookupException(
          BarcodeLookupError.notFound,
          'This barcode is not a food product.',
        );
      }
      return _parseProduct(code, product);
    } on BarcodeLookupException {
      rethrow;
    } on TimeoutException {
      throw const BarcodeLookupException(
        BarcodeLookupError.timeout,
        'The lookup took too long. Try again or enter the label.',
      );
    } on FormatException {
      throw const BarcodeLookupException(
        BarcodeLookupError.invalidResponse,
        'The product information could not be read. Enter the label instead.',
      );
    } on http.ClientException {
      throw const BarcodeLookupException(
        BarcodeLookupError.network,
        'Could not connect. Check your connection or enter the label.',
      );
    } finally {
      // Also abort a request still receiving a body when its deadline expires.
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<String> _readResponse(http.BaseRequest request) async {
    final response = await _client.send(request);
    if (response.statusCode == 404) {
      throw const BarcodeLookupException(
        BarcodeLookupError.notFound,
        'This product is not in Open Food Facts yet.',
      );
    }
    if (response.statusCode == 429) {
      throw const BarcodeLookupException(
        BarcodeLookupError.rateLimited,
        'Too many lookups. Wait a minute or enter the label.',
      );
    }
    if (response.statusCode != 200) {
      throw const BarcodeLookupException(
        BarcodeLookupError.unavailable,
        'Open Food Facts is unavailable. Try again or enter the label.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (bytes.length > 1024 * 1024) {
        throw const FormatException('Product response is too large.');
      }
    }
    return utf8.decode(bytes);
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

PackagedFood _parseProduct(String barcode, Map<String, dynamic> product) {
  final package = _quantity(
    product['product_quantity'],
    product['product_quantity_unit'],
    product['quantity'],
  );
  final serving = _quantity(
    product['serving_quantity'],
    product['serving_quantity_unit'],
    product['serving_size'],
  );
  final rawNutrients = product['nutriments'];
  final nutrients =
      rawNutrients is Map<String, dynamic> &&
          product['no_nutrition_data'] != 'on'
      ? rawNutrients
      : <String, dynamic>{};
  final declaredBasis = product['nutrition_data_per'];
  final unitsConflict =
      package != null && serving != null && package.unit != serving.unit;
  final quantityUnit = unitsConflict ? null : package?.unit ?? serving?.unit;
  NutritionBasis? basis;
  var suffix = '100g';
  // Serving values are unambiguous only when OFF says the label is per serving.
  if (declaredBasis == 'serving' &&
      [
        'energy-kcal',
        'energy-kj',
        'energy',
        'proteins',
        'carbohydrates',
        'fat',
      ].any((key) => nutrients.containsKey('${key}_serving'))) {
    basis = NutritionBasis.perServing;
    suffix = 'serving';
  } else if (quantityUnit == FoodQuantityUnit.grams) {
    basis = NutritionBasis.per100g;
  } else if (quantityUnit == FoodQuantityUnit.millilitres) {
    basis = NutritionBasis.per100ml;
  }
  // OFF calls both mass and volume values *_100g. With no reliable quantity unit
  // they must be confirmed by the user, even if nutrition_data_per says '100g'.
  double? nutrient(String key) {
    final modifier = nutrients['${key}_modifier'];
    if (modifier != null && modifier != '' && modifier != '=') return null;
    return _number(nutrients['${key}_$suffix']);
  }

  final kcal = nutrient('energy-kcal');
  final kj = nutrient('energy-kj') ?? nutrient('energy');
  return PackagedFood(
    barcode: barcode,
    name:
        _text(product['product_name_en']) ??
        _text(product['product_name']) ??
        '',
    brand: _text(product['brands']),
    basis: basis,
    kcal: kcal ?? (kj == null ? null : kj / 4.184),
    proteinG: nutrient('proteins'),
    carbsG: nutrient('carbohydrates'),
    fatG: nutrient('fat'),
    packageQuantity: package?.value,
    packageUnit: package?.unit,
    servingQuantity: serving?.value,
    servingUnit: serving?.unit,
    source: PackagedFoodSource.openFoodFacts,
  );
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

double? _number(Object? value) {
  final number = value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value.trim())
      : null;
  return number != null && number.isFinite && number >= 0 ? number : null;
}

({double value, FoodQuantityUnit unit})? _quantity(
  Object? rawValue,
  Object? rawUnit,
  Object? label,
) {
  final value = _number(rawValue);
  final unit = _text(rawUnit)?.toLowerCase();
  // These OFF fields are already normalized to grams or millilitres.
  if (value != null && value > 0 && (unit == 'g' || unit == 'ml')) {
    return (
      value: value,
      unit: unit == 'g' ? FoodQuantityUnit.grams : FoodQuantityUnit.millilitres,
    );
  }
  // Only a simple, explicit quantity is safe to use without the normalized data.
  // Multipacks and ambiguous cups/pieces/ounces are left for label confirmation.
  final text = _text(label);
  if (text == null) return null;
  final match = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s*(kg|g|ml|cl|l)\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  final numberText = match.group(1)!;
  // A comma followed by three digits can be a thousands separator. Guessing
  // would silently turn e.g. '1,000 g' into a 1 g package.
  if (RegExp(r',\d{3}$').hasMatch(numberText)) return null;
  final parsed = double.tryParse(numberText.replaceAll(',', '.'));
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  final parsedUnit = match.group(2)!.toLowerCase();
  final factor = switch (parsedUnit) {
    'kg' || 'l' => 1000.0,
    'cl' => 10.0,
    _ => 1.0,
  };
  final normalized = parsed * factor;
  if (!normalized.isFinite) return null;
  return (
    value: normalized,
    unit: parsedUnit == 'g' || parsedUnit == 'kg'
        ? FoodQuantityUnit.grams
        : FoodQuantityUnit.millilitres,
  );
}
