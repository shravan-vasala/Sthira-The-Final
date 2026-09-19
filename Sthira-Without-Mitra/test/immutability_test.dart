import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String deterministicJsonEncode(dynamic data) {
  if (data is Map) {
    final sortedKeys = data.keys.toList()..sort();
    final buffer = StringBuffer('{');
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      buffer.write('"${key}":${deterministicJsonEncode(data[key])}');
      if (i < sortedKeys.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  } else if (data is List) {
    final buffer = StringBuffer('[');
    for (int i = 0; i < data.length; i++) {
      buffer.write(deterministicJsonEncode(data[i]));
      if (i < data.length - 1) buffer.write(',');
    }
    buffer.write(']');
    return buffer.toString();
  } else if (data is String) {
    return jsonEncode(data);
  } else if (data is num || data is bool || data == null) {
    return jsonEncode(data);
  }
  return jsonEncode(data);
}

void main() {
  group('SEED-01 Expert Content Immutability', () {
    test('Meal Plan seed content has not been mutated', () {
      final file = File('assets/data/seed_meal_plan.json');
      final jsonStr = file.readAsStringSync();
      final data = jsonDecode(jsonStr);
      
      final extracted = [];
      for (var m in (data['meals'] as List? ?? [])) {
        final mealInfo = {
          'name': m['name'],
          'type': m['type'],
          'calories': m['calories'],
          'items': (m['items'] as List? ?? []).map((i) => {
            'name': i['name'],
            'quantity': i['quantity'],
            'calories': i['calories'],
          }).toList(),
          'suggestions': m['suggestions'] ?? [],
        };
        extracted.add(mealInfo);
      }
      
      final serialized = deterministicJsonEncode(extracted);
      final hash = sha256.convert(utf8.encode(serialized)).toString();
      
      // The golden hash captured from commit 1b88ec6 state
      // Updated by SEED-01 to reflect inclusion of clinical plan guidelines
      expect(hash, 'a711dc0940793ca4db12d858c40865090e2f1191b66b6f6a32f8c09d93bc33dd');
    });

    test('Workout Plan seed content has not been mutated', () {
      final file = File('assets/data/seed_workout_plan.json');
      final jsonStr = file.readAsStringSync();
      final data = jsonDecode(jsonStr);
      
      final extracted = [];
      for (var d in (data['days'] as List? ?? [])) {
        final dayInfo = {
          'dayId': d['dayId'],
          'label': d['label'],
          'sections': <dynamic>[],
        };
        for (var s in (d['sections'] as List? ?? [])) {
          final sec = {
            'title': s['title'],
            'exercises': <dynamic>[],
          };
          for (var e in (s['exercises'] as List? ?? [])) {
            final ex = {
                'name': e['name'],
                'displayName': e['displayName'],
                'youtubeUrl': e['youtubeUrl'],
                'reps': e['reps'] ?? [],
                'note': e['note'],
                'sideInfo': e['sideInfo'],
                'restSecondsAfterSet': e['restSecondsAfterSet']
            };
            (sec['exercises'] as List).add(ex);
          }
          (dayInfo['sections'] as List).add(sec);
        }
        extracted.add(dayInfo);
      }
      
      final serialized = deterministicJsonEncode(extracted);
      final hash = sha256.convert(utf8.encode(serialized)).toString();

      // The golden hash captured from commit 1b88ec6 state
      expect(hash, '125c7902b0bb5ca01ffc79c8067083214d5db5ce97cc57f400cbb05803af246d');
    });
  });
}
