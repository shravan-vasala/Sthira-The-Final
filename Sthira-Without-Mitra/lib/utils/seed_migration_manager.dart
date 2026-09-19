import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../models/meal_plan.dart';
import '../models/workout_plan.dart';

class SeedMigrationManager {
  static Future<void> seedOrMigrateMeals(Isar isar, String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final assetPlan = MealPlan.fromJson(map);
    final String seedName = assetPlan.planName;

    final storedExact = isar.mealPlans.where().planNameEqualTo(seedName).findFirstSync();

    if (storedExact == null) {
      final insertPlan = assetPlan.copyWith(source: 'seed');
      await isar.writeTxn(() async {
        await isar.mealPlans.put(insertPlan);
      });
      return;
    }

    if (storedExact.source == 'seed') {
      final storedVersion = storedExact.seedVersion ?? 0;
      final assetVersion = assetPlan.seedVersion ?? 1;

      if (storedVersion < assetVersion) {
        final updatePlan = assetPlan.copyWith(source: 'seed');
        updatePlan.id = storedExact.id;
        await isar.writeTxn(() async {
          await isar.mealPlans.put(updatePlan);
        });
      }
      return;
    }

    // If source is 'user' or empty, it's a user plan or legacy plan. 
    // Insert alongside as ' (Expert)' if it doesn't already exist or needs updating.
    if (storedExact.source == 'user' || storedExact.source.isEmpty) {
      final String expertName = '$seedName (Expert)';
      final storedExpert = isar.mealPlans.where().planNameEqualTo(expertName).findFirstSync();

      if (storedExpert == null) {
        final insertExpert = assetPlan.copyWith(planName: expertName, source: 'seed');
        await isar.writeTxn(() async {
          await isar.mealPlans.put(insertExpert);
        });
      } else if (storedExpert.source == 'seed') {
        final storedVersion = storedExpert.seedVersion ?? 0;
        final assetVersion = assetPlan.seedVersion ?? 1;

        if (storedVersion < assetVersion) {
          final updateExpert = assetPlan.copyWith(planName: expertName, source: 'seed');
          updateExpert.id = storedExpert.id;
          await isar.writeTxn(() async {
            await isar.mealPlans.put(updateExpert);
          });
        }
      }
    }
  }

  static Future<void> seedOrMigrateWorkouts(Isar isar, String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final assetPlan = WorkoutPlan.fromJson(map);
    final String seedName = assetPlan.planName;

    final storedExact = isar.workoutPlans.where().planNameEqualTo(seedName).findFirstSync();

    if (storedExact == null) {
      final insertPlan = assetPlan.copyWith(source: 'seed');
      await isar.writeTxn(() async {
        await isar.workoutPlans.put(insertPlan);
      });
      return;
    }

    if (storedExact.source == 'seed') {
      final storedVersion = storedExact.seedVersion ?? 0;
      final assetVersion = assetPlan.seedVersion ?? 1;

      if (storedVersion < assetVersion) {
        final updatePlan = assetPlan.copyWith(source: 'seed');
        updatePlan.id = storedExact.id;
        await isar.writeTxn(() async {
          await isar.workoutPlans.put(updatePlan);
        });
      }
      return;
    }

    // Legacy / User Plan
    if (storedExact.source == 'user' || storedExact.source.isEmpty) {
      final String expertName = '$seedName (Expert)';
      final storedExpert = isar.workoutPlans.where().planNameEqualTo(expertName).findFirstSync();

      if (storedExpert == null) {
        final insertExpert = assetPlan.copyWith(planName: expertName, source: 'seed');
        await isar.writeTxn(() async {
          await isar.workoutPlans.put(insertExpert);
        });
      } else if (storedExpert.source == 'seed') {
        final storedVersion = storedExpert.seedVersion ?? 0;
        final assetVersion = assetPlan.seedVersion ?? 1;

        if (storedVersion < assetVersion) {
          final updateExpert = assetPlan.copyWith(planName: expertName, source: 'seed');
          updateExpert.id = storedExpert.id;
          await isar.writeTxn(() async {
            await isar.workoutPlans.put(updateExpert);
          });
        }
      }
    }
  }
}
