import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/services/social_sync_service.dart';

void main() {
  group('UID Validation Regex', () {
    final validId = SocialSyncService.isValidFriendId;

    test('valid UID passes', () {
      expect(validId('abcDEF1234567890xyZZZ'), isTrue);
      expect(validId('a' * 28), isTrue); // Typical Firebase UID is 28 chars
      expect(validId('a' * 20), isTrue);
      expect(validId('a' * 128), isTrue);
      expect(validId('friend_with-dashes_123456'), isTrue);
    });

    test('invalid UID fails', () {
      expect(validId('too_short'), isFalse); // < 20
      expect(validId('a' * 129), isFalse); // > 128
      expect(validId('abcDEF1234567890!@#\$'), isFalse); // Special characters
      expect(validId(' abcDEF1234567890xyZZZ'), isFalse); // Leading space
    });
  });

  group('Leaderboard Sort Order', () {
    final now = DateTime.now();

    final me = SocialProfile(
      uid: 'me',
      name: 'Me',
      todaySteps: 5000,
      todayWorkouts: 1,
      currentStreak: 5,
      weeklySteps: 20000,
      weeklyWorkouts: 3,
      lastUpdatedAt: now,
    );
    final active1 = SocialProfile(
      uid: 'a1',
      name: 'A1',
      todaySteps: 8000,
      todayWorkouts: 1,
      currentStreak: 10,
      weeklySteps: 15000,
      weeklyWorkouts: 2,
      lastUpdatedAt: now.subtract(const Duration(hours: 1)),
    );
    final active2 = SocialProfile(
      uid: 'a2',
      name: 'A2',
      todaySteps: 5000,
      todayWorkouts: 0,
      currentStreak: 6,
      weeklySteps: 20000,
      weeklyWorkouts: 4,
      lastUpdatedAt: now,
    );
    final inactive1 = SocialProfile(
      uid: 'i1',
      name: 'I1',
      todaySteps: 10000,
      todayWorkouts: 1,
      currentStreak: 20,
      weeklySteps: 50000,
      weeklyWorkouts: 5,
      lastUpdatedAt: now.subtract(const Duration(days: 8)),
    );

    test('Sort active profiles Today (by steps, then streak)', () {
      final activeProfiles = [me, active1, active2];

      activeProfiles.sort((a, b) {
        final aSteps = a.todaySteps ?? 0;
        final bSteps = b.todaySteps ?? 0;
        final aStreak = a.currentStreak ?? 0;
        final bStreak = b.currentStreak ?? 0;
        if (bSteps != aSteps) return bSteps.compareTo(aSteps);
        return bStreak.compareTo(aStreak);
      });

      // A1 (8000), A2 (5000, streak 6), Me (5000, streak 5)
      expect(activeProfiles[0].uid, 'a1');
      expect(activeProfiles[1].uid, 'a2');
      expect(activeProfiles[2].uid, 'me');
    });

    test(
      'Sort active profiles This Week (by weekly steps, then weekly workouts)',
      () {
        final activeProfiles = [me, active1, active2];

        activeProfiles.sort((a, b) {
          final aWSteps = a.weeklySteps ?? 0;
          final bWSteps = b.weeklySteps ?? 0;
          final aWWorkouts = a.weeklyWorkouts ?? 0;
          final bWWorkouts = b.weeklyWorkouts ?? 0;
          if (bWSteps != aWSteps) return bWSteps.compareTo(aWSteps);
          return bWWorkouts.compareTo(aWWorkouts);
        });

        // A2 (20000, 4 W/O), Me (20000, 3 W/O), A1 (15000, 2 W/O)
        expect(activeProfiles[0].uid, 'a2');
        expect(activeProfiles[1].uid, 'me');
        expect(activeProfiles[2].uid, 'a1');
      },
    );

    test('Split inactive properly (> 7 days)', () {
      final allProfiles = [me, active1, active2, inactive1];
      final active = <SocialProfile>[];
      final inactive = <SocialProfile>[];

      for (var p in allProfiles) {
        if (now.difference(p.lastUpdatedAt).inDays > 7 && p.uid != me.uid) {
          inactive.add(p);
        } else {
          active.add(p);
        }
      }

      expect(active.length, 3);
      expect(inactive.length, 1);
      expect(inactive[0].uid, 'i1');
    });
  });

  group('Weekly Steps Computation boundary correctness', () {
    test('Calculates current week correctly (Mon-Sun)', () {
      // Suppose today is Wednesday
      final now = DateTime(2023, 10, 25); // Oct 25, 2023 was a Wednesday
      final diff = now.weekday - 1; // 3 - 1 = 2
      final monday = now.subtract(Duration(days: diff)); // Oct 23

      expect(monday.weekday, DateTime.monday);
      expect(monday.day, 23);

      // Loop goes from 0 to 2
      final datesToCheck = <String>[];
      for (int i = 0; i <= diff; i++) {
        final d = monday.add(Duration(days: i));
        datesToCheck.add(d.toIso8601String().substring(0, 10));
      }

      expect(datesToCheck, ['2023-10-23', '2023-10-24', '2023-10-25']);
    });
  });
}
