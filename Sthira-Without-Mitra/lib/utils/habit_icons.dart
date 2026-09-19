import 'package:flutter/material.dart';

/// Habit icons are Material [IconData], stored as string keys.
/// Legacy emoji values still resolve for existing saved habits.
class HabitIcons {
  HabitIcons._();

  static const List<({String id, IconData icon})> options = [
    (id: 'check', icon: Icons.check_circle_outline_rounded),
    (id: 'bedtime', icon: Icons.dark_mode_outlined),
    (id: 'walk', icon: Icons.directions_walk_outlined),
    (id: 'water', icon: Icons.water_drop_outlined),
    (id: 'mind', icon: Icons.self_improvement_outlined),
    (id: 'book', icon: Icons.menu_book_outlined),
    (id: 'meds', icon: Icons.medication_outlined),
    (id: 'food', icon: Icons.restaurant_outlined),
    (id: 'train', icon: Icons.fitness_center_outlined),
    (id: 'run', icon: Icons.directions_run_outlined),
    (id: 'greens', icon: Icons.eco_outlined),
    (id: 'amla', icon: Icons.local_drink_outlined),
    (id: 'shots', icon: Icons.emoji_food_beverage_outlined),
    (id: 'nuts', icon: Icons.grain_outlined),
    (id: 'sun', icon: Icons.wb_sunny_outlined),
    (id: 'skin', icon: Icons.face_retouching_natural_outlined),
    (id: 'hair', icon: Icons.spa_outlined),
    (id: 'no_screen', icon: Icons.phonelink_erase_outlined),
    (id: 'no_fried', icon: Icons.fastfood_outlined),
    (id: 'no_package', icon: Icons.takeout_dining_outlined),
  ];

  static IconData resolve(String keyOrEmoji) {
    switch (keyOrEmoji) {
      case '😴':
      case 'bedtime':
        return Icons.dark_mode_outlined;
      case '🚶':
      case 'walk':
        return Icons.directions_walk_outlined;
      case '🏃':
      case 'run':
        return Icons.directions_run_outlined;
      case '💧':
      case 'water':
        return Icons.water_drop_outlined;
      case '✅':
      case 'check':
        return Icons.check_circle_outline_rounded;
      case '🧘':
      case 'mind':
        return Icons.self_improvement_outlined;
      case '📚':
      case 'book':
        return Icons.menu_book_outlined;
      case '💊':
      case 'meds':
        return Icons.medication_outlined;
      case '🍎':
      case 'food':
        return Icons.restaurant_outlined;
      case '🏋️':
      case 'train':
        return Icons.fitness_center_outlined;
      case '🚭':
      case 'smoke_free':
        return Icons.smoke_free_outlined;
      case '🥦':
      case 'greens':
        return Icons.eco_outlined;
      case 'amla':
        return Icons.local_drink_outlined;
      case 'skin':
        return Icons.face_retouching_natural_outlined;
      case 'hair':
        return Icons.spa_outlined;
      case 'shots':
        return Icons.emoji_food_beverage_outlined;
      case 'nuts':
        return Icons.grain_outlined;
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'no_screen':
        return Icons.phonelink_erase_outlined;
      case 'no_fried':
        return Icons.fastfood_outlined;
      case 'no_package':
        return Icons.takeout_dining_outlined;
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.icon;
        }
        return Icons.check_circle_outline_rounded;
    }
  }

  /// Prefer storing stable keys when saving.
  static String normalize(String keyOrEmoji) {
    switch (keyOrEmoji) {
      case '😴':
        return 'bedtime';
      case '🚶':
        return 'walk';
      case '🏃':
        return 'run';
      case '💧':
        return 'water';
      case '✅':
        return 'check';
      case '🧘':
        return 'mind';
      case '📚':
        return 'book';
      case '💊':
        return 'meds';
      case '🍎':
        return 'food';
      case '🏋️':
        return 'train';
      case '🚭':
        return 'smoke_free';
      case '🥦':
        return 'greens';
      case 'amla':
        return 'amla';
      case 'skin':
        return 'skin';
      case 'hair':
        return 'hair';
      case 'shots':
        return 'shots';
      case 'nuts':
        return 'nuts';
      case 'sun':
        return 'sun';
      case 'no_screen':
        return 'no_screen';
      case 'no_fried':
        return 'no_fried';
      case 'no_package':
        return 'no_package';
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.id;
        }
        return 'check';
    }
  }
}
