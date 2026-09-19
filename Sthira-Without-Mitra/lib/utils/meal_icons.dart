import 'package:flutter/material.dart';

class MealIcons {
  MealIcons._();

  static const List<({String id, IconData icon})> options = [
    (id: 'breakfast', icon: Icons.breakfast_dining_outlined),
    (id: 'lunch', icon: Icons.lunch_dining_outlined),
    (id: 'dinner', icon: Icons.dinner_dining_outlined),
    (id: 'snack', icon: Icons.fastfood_outlined),
    (id: 'drink', icon: Icons.local_cafe_outlined),
    (id: 'coffee', icon: Icons.emoji_food_beverage_outlined),
    (id: 'healthy', icon: Icons.eco_outlined),
    (id: 'soup', icon: Icons.soup_kitchen_outlined),
    (id: 'treat', icon: Icons.cake_outlined),
    (id: 'restaurant', icon: Icons.restaurant_outlined),
    (id: 'set_meal', icon: Icons.set_meal_outlined),
    (id: 'egg', icon: Icons.egg_alt_outlined),
    (id: 'pizza', icon: Icons.local_pizza_outlined),
    (id: 'ramen', icon: Icons.ramen_dining_outlined),
    (id: 'icecream', icon: Icons.icecream_outlined),
    (id: 'cookie', icon: Icons.cookie_outlined),
    (id: 'kebab', icon: Icons.kebab_dining_outlined),
  ];

  static IconData resolve(String? keyOrEmoji) {
    if (keyOrEmoji == null) return Icons.restaurant_outlined;

    switch (keyOrEmoji) {
      case '🍳':
        return Icons.egg_alt_outlined;
      case '🍛':
        return Icons.lunch_dining_outlined;
      case '🍎':
        return Icons.fastfood_outlined;
      case '🍽️':
        return Icons.dinner_dining_outlined;
      case '🍴':
        return Icons.restaurant_outlined;
      case '🥤':
        return Icons.local_cafe_outlined;
      case '🍌':
        return Icons.fastfood_outlined;
      case '🥜':
        return Icons.eco_outlined;
      case '🍚':
        return Icons.lunch_dining_outlined;
      case '🫖':
        return Icons.emoji_food_beverage_outlined;
      case '🍪':
        return Icons.cake_outlined;
      case '🥩':
        return Icons.dinner_dining_outlined;
      case '🥑':
        return Icons.eco_outlined;
      case '🥪':
        return Icons.fastfood_outlined;
      case '🥣':
        return Icons.soup_kitchen_outlined;
      case '🥗':
        return Icons.eco_outlined;
      case 'pizza':
        return Icons.local_pizza_outlined;
      case 'ramen':
        return Icons.ramen_dining_outlined;
      case 'icecream':
        return Icons.icecream_outlined;
      case 'cookie':
        return Icons.cookie_outlined;
      case 'kebab':
        return Icons.kebab_dining_outlined;
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.icon;
        }
        return Icons.restaurant_outlined;
    }
  }

  static String normalize(String? keyOrEmoji) {
    if (keyOrEmoji == null) return 'restaurant';

    switch (keyOrEmoji) {
      case '🍳':
        return 'egg';
      case '🍛':
        return 'lunch';
      case '🍎':
        return 'snack';
      case '🍽️':
        return 'dinner';
      case '🍴':
        return 'restaurant';
      case '🥤':
        return 'drink';
      case '🍌':
        return 'snack';
      case '🥜':
        return 'healthy';
      case '🍚':
        return 'lunch';
      case '🫖':
        return 'coffee';
      case '🍪':
        return 'treat';
      case '🥩':
        return 'dinner';
      case '🥑':
        return 'healthy';
      case '🥪':
        return 'snack';
      case '🥣':
        return 'soup';
      case '🥗':
        return 'healthy';
      case 'pizza':
        return 'pizza';
      case 'ramen':
        return 'ramen';
      case 'icecream':
        return 'icecream';
      case 'cookie':
        return 'cookie';
      case 'kebab':
        return 'kebab';
      default:
        for (final o in options) {
          if (o.id == keyOrEmoji) return o.id;
        }
        return 'restaurant';
    }
  }
}
