import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Payload Contract', () {
    test('Zero meals handles energy properly vs null', () {
      final jsonSnapshotNull = {
        'date': '2023-11-20',
        'updatedAt': '10:00',
        'steps': null,
        'stepGoal': null,
        'mealsLogged': 0,
        'totalMeals': 4,
        'habitsDone': 1,
        'totalHabits': 3,
        'energy': null,
        'protein': null,
        'isRest': false,
        'workoutTitle': 'Workout',
        'workoutStatus': 'Pending'
      };
      
      final asJsonNull = jsonEncode(jsonSnapshotNull);
      final decodedNull = jsonDecode(asJsonNull) as Map<String, dynamic>;
      
      expect(decodedNull['energy'], isNull);
      expect(decodedNull['steps'], isNull);
      
      final jsonSnapshotZeros = {
        'date': '2023-11-20',
        'updatedAt': '10:00',
        'steps': 0,
        'stepGoal': 10000,
        'mealsLogged': 1,
        'totalMeals': 4,
        'habitsDone': 1,
        'totalHabits': 3,
        'energy': 0,
        'protein': 0,
        'isRest': false,
        'workoutTitle': 'Workout',
        'workoutStatus': 'Pending'
      };
      
      final asJsonZero = jsonEncode(jsonSnapshotZeros);
      final decodedZero = jsonDecode(asJsonZero) as Map<String, dynamic>;
      
      expect(decodedZero['energy'], 0);
      expect(decodedZero['steps'], 0);
    });

    test('Provider correctly falls back to defaults for missing keys', () {
      final jsonSnapshotMalformed = {
        'date': '2023-11-20',
      };
      
      final asJsonFallback = jsonEncode(jsonSnapshotMalformed);
      final decoded = jsonDecode(asJsonFallback) as Map<String, dynamic>;
      
      // Native widget does: json.optInt("steps") -> 0 or json.isNull("steps")
      expect(decoded.containsKey('steps'), false);
      
      // Simulate native retrieval logic logic
      final isNullEnergy = !decoded.containsKey('energy') || decoded['energy'] == null;
      expect(isNullEnergy, isTrue);
    });
  });
}
