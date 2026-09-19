import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  late SharedPreferences _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final modeStr = _prefs.getString('themeMode') ?? 'system';
    return ThemeMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString('themeMode', mode.name);
  }
}
