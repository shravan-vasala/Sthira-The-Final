import 'package:flutter/material.dart';

abstract class AppColorsPalette {
  Color get primary;
  Color get primaryLight;
  Color get primaryDark;

  /// Brand accent for small text on surfaces; the peach remains the fill color.
  Color get accentText;
  Color get indigo;
  Color get lavender;
  Color get scaffoldBg;
  Color get background;

  /// Literal white. Use [onPrimary] for content on the peach accent.
  Color get white;

  /// Fill for text fields sitting on [card] / [surface] (never literal white in dark).
  Color get inputFill;
  Color get surface;
  Color get card;
  Color get onPrimary;
  Color get onSurface;
  Color get warning;
  Color get orange;
  Color get green;
  Color get greenLight;
  Color get red;
  Color get redLight;
  Color get pink;
  Color get pinkIcon;
  Color get mint;
  Color get mintIcon;
  Color get insetSurface;
  Color get textDark;
  Color get textMedium;
  Color get textLight;
  Color get border;
  Color get divider;
  LinearGradient get primaryGradient;
  LinearGradient get primaryGradientVertical;
  Color get shadow;
  Color get accentGlow;
  Color get gold;
  Color get goldMuted;
  Color get silver;
  Color get bronze;
}

class AppColorsLight implements AppColorsPalette {
  @override
  Color get primary => const Color(0xFFE29B65);
  @override
  Color get primaryLight => const Color(0xFFEDBA94);
  @override
  Color get primaryDark => const Color(0xFFC57A42);
  @override
  Color get accentText => indigo;
  @override
  Color get indigo => const Color(0xFF8C593C);
  @override
  Color get lavender => const Color(0xFFF2E2D3);
  @override
  Color get scaffoldBg => const Color(0xFFFAF2EA);
  @override
  Color get background => scaffoldBg;
  @override
  Color get white => const Color(0xFFFFFFFF);
  @override
  Color get inputFill => const Color(0xFFFDF8F3);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get card => const Color(0xFFFFFFFF);
  @override
  Color get onPrimary => const Color(0xFF2D1A25); // Dark text on the sandy button
  @override
  Color get onSurface => const Color(0xFF2D1A25);
  @override
  Color get warning => const Color(0xFFE0912F);
  @override
  Color get orange => const Color(0xFFE0912F);
  @override
  Color get green => const Color(0xFF7FA35C);
  @override
  Color get greenLight => const Color(0xFFEAF0DD);
  @override
  Color get red => const Color(0xFFD95F4C);
  @override
  Color get redLight => const Color(0xFFF9E2DC);
  @override
  Color get pink => const Color(0xFFF7E3E7);
  @override
  Color get pinkIcon => const Color(0xFFD9768C);
  @override
  Color get mint => const Color(0xFFE3EEEA);
  @override
  Color get mintIcon => const Color(0xFF4E9B8F);
  @override
  Color get insetSurface => const Color(0xFFF5EBE1);
  @override
  Color get textDark => const Color(0xFF2D1A25);
  @override
  Color get textMedium => const Color(0xFF8C593C);
  @override
  Color get textLight => const Color(0xFF9A7A66);
  @override
  Color get border => const Color(0xFFEADBD1);
  @override
  Color get divider => const Color(0xFFF3E8DF);
  @override
  LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFFE7A473), Color(0xFFE29B65)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  @override
  LinearGradient get primaryGradientVertical => const LinearGradient(
    colors: [Color(0xFFE7A473), Color(0xFFE29B65)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  @override
  Color get shadow => textDark.withValues(alpha: 0.08);
  @override
  Color get accentGlow => const Color(0x29E29B65);
  @override
  Color get gold => const Color(0xFFD4AF37);
  @override
  Color get goldMuted => const Color(0xFFF9F1D8);
  @override
  Color get silver => const Color(0xFFC0C0C0);
  @override
  Color get bronze => const Color(0xFFCD7F32);
}

class AppColorsDark implements AppColorsPalette {
  @override
  Color get primary => const Color(0xFFE29B65);
  @override
  Color get primaryLight => const Color(0xFFEDBA94);
  @override
  Color get primaryDark => const Color(0xFFC57A42);
  @override
  Color get accentText => primary;
  @override
  Color get indigo => const Color(0xFF8C593C);
  @override
  Color get lavender => const Color(0xFF251E1C);
  @override
  Color get scaffoldBg => const Color(0xFF0F1513);
  @override
  Color get background => scaffoldBg;
  @override
  Color get white => const Color(0xFFFFFFFF);
  @override
  Color get inputFill => const Color(0xFF1C2622);
  @override
  Color get surface => const Color(0xFF171F1B);
  @override
  Color get card => const Color(0xFF171F1B);
  @override
  Color get onPrimary => const Color(0xFF2D1A25);
  @override
  Color get onSurface => const Color(0xFFEFE8EA);
  @override
  Color get warning => const Color(0xFFE0912F);
  @override
  Color get orange => const Color(0xFFE0912F);
  @override
  Color get green => const Color(0xFF7FA35C);
  @override
  Color get greenLight => const Color(0xFF2E3B22);
  @override
  Color get red => const Color(0xFFD95F4C);
  @override
  Color get redLight => const Color(0xFF4A241E);
  @override
  Color get pink => const Color(0xFF45242C);
  @override
  Color get pinkIcon => const Color(0xFFD9768C);
  @override
  Color get mint => const Color(0xFF1F3833);
  @override
  Color get mintIcon => const Color(0xFF4E9B8F);
  @override
  Color get insetSurface => const Color(0xFF1C2622);
  @override
  Color get textDark => const Color(0xFFEFE8EA);
  @override
  Color get textMedium => const Color(0xFFB5A5AA);
  @override
  Color get textLight => const Color(0xFF96878B);
  @override
  Color get border => const Color(0xFF332A2F);
  @override
  Color get divider => const Color(0xFF221C1F);
  @override
  LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFFE7A473), Color(0xFFE29B65)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  @override
  LinearGradient get primaryGradientVertical => const LinearGradient(
    colors: [Color(0xFFEDBA94), Color(0xFFD4885A), Color(0xFFAA6B3C)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  @override
  Color get shadow => const Color(0xFF000000).withValues(alpha: 0.3);
  @override
  Color get accentGlow => const Color(0x33E29B65);
  @override
  Color get gold => const Color(0xFFFFD700);
  @override
  Color get goldMuted => const Color(0xFF4A3D12);
  @override
  Color get silver => const Color(0xFFE0E0E0);
  @override
  Color get bronze => const Color(0xFFE48C3B);
}

class AppColors {
  static final light = AppColorsLight();
  static final dark = AppColorsDark();
}

extension AppColorsExt on BuildContext {
  AppColorsPalette get colors => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
}
