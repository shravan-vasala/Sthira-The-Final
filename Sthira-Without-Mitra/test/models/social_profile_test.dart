import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/social_profile.dart';

void main() {
  group('SocialProfile backward compatibility', () {
    test('decodes legacy docs without todayScore or weekScore gracefully', () {
      final legacyJson = {
        'uid': 'user123',
        'name': 'Priya',
        'avatarUrl': null,
        'todaySteps': 5000,
        'todayWorkouts': 1,
        'currentStreak': 4,
        'weeklySteps': 35000,
        'weeklyWorkouts': 3,
        'latestBadge': null,
        'lastUpdatedAt': 1709294800000,
        'allowedReaders': ['friendA', 'friendB'],
      };

      final profile = SocialProfile.fromJson(legacyJson);

      expect(profile.uid, 'user123');
      expect(profile.todayScore, isNull);
      expect(profile.weekScore, isNull);
      expect(profile.todaySteps, 5000);
      expect(profile.name, 'Priya');
    });

    test('decodes rich docs with todayScore and weekScore present', () {
      final richJson = {
        'uid': 'user456',
        'name': 'Rahul',
        'avatarUrl': null,
        'todaySteps': 12000,
        'todayWorkouts': 2,
        'currentStreak': 14,
        'weeklySteps': 85000,
        'weeklyWorkouts': 5,
        'latestBadge': null,
        'lastUpdatedAt': 1709294800000,
        'allowedReaders': [],
        'todayScore': 95,
        'weekScore': 87,
      };

      final profile = SocialProfile.fromJson(richJson);

      expect(profile.uid, 'user456');
      expect(profile.todayScore, 95);
      expect(profile.weekScore, 87);
    });
  });
}
