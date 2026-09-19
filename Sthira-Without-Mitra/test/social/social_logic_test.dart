import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/social_profile.dart'; // Adjust import as needed

void main() {
  group('SocialProfile Tests', () {
    test('toJson/fromJson serialization with new fields', () {
      final now = DateTime.now();
      final profile = SocialProfile(
        uid: 'user123',
        name: 'John',
        todaySteps: 5000,
        todayWorkouts: 1,
        currentStreak: 3,
        weeklySteps: 25000,
        weeklyWorkouts: 4,
        lastUpdatedAt: now,
        allowedReaders: ['friend456', 'friend789'],
      );

      final json = profile.toJson();
      expect(json['weeklySteps'], 25000);
      expect(json['weeklyWorkouts'], 4);
      expect(json['allowedReaders'], ['friend456', 'friend789']);

      final restored = SocialProfile.fromJson(json);
      expect(restored.uid, 'user123');
      expect(restored.weeklySteps, 25000);
      expect(restored.weeklyWorkouts, 4);
      expect(restored.allowedReaders, ['friend456', 'friend789']);
    });
  });
}
