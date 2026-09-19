import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MEAL-01 AI vs Nutritionist Boundary', () {
    test('suggestMealStream does not use Meal.suggestions', () {
      final file = File('lib/services/gemini_food_service.dart');
      final code = file.readAsStringSync();
      
      // Extract the suggestMealStream method body loosely
      final streamRegex = RegExp(r'Stream<String> suggestMealStream\(\{.*?\)\s*async\*\s*\{([\s\S]*?)try\s*\{', multiLine: true, dotAll: true);
      final match = streamRegex.firstMatch(code);
      
      if (match != null) {
        final body = match.group(1)!;
        // Assert that the AI feature never reads from the nutritionist guidelines
        expect(
          body.contains('.suggestions') || body.contains('suggestions:'),
          isFalse, 
          reason: 'CRITICAL BOUNDARY VIOLATION: AI prompt must not be contaminated by nutritionist suggestions.'
        );
      }
      
      final promptSection = code.substring(code.indexOf('suggestMealStream'));
      expect(
        promptSection.contains('.suggestions'),
        isFalse,
        reason: 'CRITICAL BOUNDARY VIOLATION: suggestMealStream contains a reference to suggestions in its body or prompt.'
      );
    });
  });
}
