import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

void main() {
  test('AppTheme.light initializes without crashing', () {
    final theme = AppTheme.light;
    expect(theme, isNotNull);
  });
  test('AppTheme.dark initializes without crashing', () {
    final theme = AppTheme.dark;
    expect(theme, isNotNull);
  });
  test(
    'small accent labels and primary content remain readable in both themes',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance();
        final y = b.computeLuminance();
        return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
      }

      for (final palette in [AppColors.light, AppColors.dark]) {
        expect(
          contrast(AppTypography(palette).sectionLabel.color!, palette.card),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(palette.accentText, palette.scaffoldBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(palette.onPrimary, palette.primary),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(AppTheme.light.colorScheme.onPrimary, AppColors.light.onPrimary);
    },
  );
}
