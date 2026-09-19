import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static TextStyle numeric(TextStyle base) => base.copyWith(
    fontFeatures: [...?base.fontFeatures, const FontFeature.tabularFigures()],
  );

  static ThemeData get light {
    final colors = AppColorsLight();
    final text = AppTypography(colors);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'General Sans',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight().scaffoldBg,
      primaryColor: AppColorsLight().primary,
      iconTheme: IconThemeData(
        size: IconSize.nav,
        color: AppColorsLight().textDark,
      ),
      colorScheme: ColorScheme.light(
        primary: AppColorsLight().primary,
        secondary: AppColorsLight().indigo,
        surface: AppColorsLight().white,
        error: AppColorsLight().red,
        onPrimary: colors.onPrimary,
        onSecondary: AppColorsLight().white,
        onSurface: AppColorsLight().textDark,
        onError: colors.white,
      ),
      textTheme: _buildTextTheme(
        textDark: colors.textDark,
        textMedium: colors.textMedium,
        textLight: colors.textLight,
        primary: colors.primary,
        text: text,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: Spacing.screen,
        titleTextStyle: text.screenTitle.copyWith(
          color: AppColorsLight().textDark,
        ),
        iconTheme: IconThemeData(color: AppColorsLight().textDark),
        actionsIconTheme: IconThemeData(color: AppColorsLight().textDark),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.bodyStrong,
        unselectedLabelStyle: text.body.copyWith(
          color: AppColorsLight().textMedium,
        ),
        indicatorColor: AppColorsLight().primary,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.fill,
        labelColor: AppColorsLight().textDark,
        unselectedLabelColor: AppColorsLight().textMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight().primary,
          foregroundColor: AppColorsLight().onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: text.bodyStrong,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsLight().primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.onPrimary;
            }
            return AppColorsLight().textMedium;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColorsLight().border, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.control),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accentText,
          side: BorderSide(color: AppColorsLight().primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: text.bodyStrong,
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentText,
          textStyle: text.bodyStrong,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: IconSize.nav,
          padding: const EdgeInsets.all(Gap.x8),
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColorsLight().card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColorsLight().card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight().card,
        actionTextColor: AppColorsLight().accentText,
        closeIconColor: AppColorsLight().textMedium,
        showCloseIcon: true,
        contentTextStyle: text.body.copyWith(color: AppColorsLight().textDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        insetPadding: const EdgeInsets.only(
          bottom: Gap.x16,
          left: Spacing.screen,
          right: Spacing.screen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight().inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsLight().border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsLight().border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsLight().primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.block,
          vertical: Spacing.block,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: text.body.copyWith(color: AppColorsLight().textMedium),
        floatingLabelStyle: text.body.copyWith(color: colors.accentText),
        hintStyle: text.body.copyWith(color: AppColorsLight().textLight),
      ),
      dividerTheme: DividerThemeData(
        color: AppColorsLight().divider,
        thickness: 1,
        space: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsLight().green;
          }
          return Colors.transparent;
        }),
        shape: const CircleBorder(),
        side: BorderSide(color: AppColorsLight().border, width: 2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColorsLight().primary,
        inactiveTrackColor: AppColorsLight().insetSurface,
        trackHeight: 6,
        thumbColor: AppColorsLight().primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsLight().card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.screenTitle.copyWith(
          color: AppColorsLight().textDark,
        ),
        contentTextStyle: text.body.copyWith(
          color: AppColorsLight().textMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.body.copyWith(color: AppColorsLight().textDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColorsLight().card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyStrong.copyWith(
          color: AppColorsLight().textDark,
        ),
        subtitleTextStyle: text.caption.copyWith(
          color: AppColorsLight().textMedium,
        ),
        iconColor: AppColorsLight().textMedium,
      ),
      canvasColor: AppColorsLight().card,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsLight().card,
        textStyle: text.body.copyWith(color: AppColorsLight().textDark),
      ),
    );
  }

  static ThemeData get dark {
    final colors = AppColorsDark();
    final text = AppTypography(colors);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'General Sans',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark().scaffoldBg,
      primaryColor: AppColorsDark().primary,
      iconTheme: IconThemeData(size: IconSize.nav, color: colors.textDark),

      colorScheme: ColorScheme.dark(
        primary: AppColorsDark().primary,
        secondary: AppColorsDark().indigo,
        surface: AppColorsDark().surface,
        error: AppColorsDark().red,
        onPrimary: AppColorsDark().onPrimary,
        onSecondary: AppColorsDark().onPrimary,
        onSurface: AppColorsDark().onSurface,
        onError: colors.onPrimary,
      ),
      textTheme: _buildTextTheme(
        textDark: colors.textDark,
        textMedium: colors.textMedium,
        textLight: colors.textLight,
        primary: colors.primary,
        text: text,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: Spacing.screen,
        titleTextStyle: text.screenTitle.copyWith(
          color: AppColorsDark().textDark,
        ),
        iconTheme: IconThemeData(color: AppColorsDark().textDark),
        actionsIconTheme: IconThemeData(color: AppColorsDark().textDark),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.bodyStrong,
        unselectedLabelStyle: text.body.copyWith(
          color: AppColorsDark().textMedium,
        ),
        indicatorColor: AppColorsDark().primary,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.fill,
        labelColor: AppColorsDark().textDark,
        unselectedLabelColor: AppColorsDark().textMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark().primary,
          foregroundColor: AppColorsDark().onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: text.bodyStrong,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark().primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark().surface;
            }
            return AppColorsDark().textMedium;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: AppColorsDark().border, width: 1),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.control),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark().primary,
          side: BorderSide(color: AppColorsDark().primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: text.bodyStrong,
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: text.bodyStrong,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: IconSize.nav,
          padding: const EdgeInsets.all(Gap.x8),
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColorsDark().card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColorsDark().card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark().card,
        actionTextColor: AppColorsDark().accentText,
        closeIconColor: AppColorsDark().textMedium,
        showCloseIcon: true,
        contentTextStyle: text.body.copyWith(color: AppColorsDark().textDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        insetPadding: const EdgeInsets.only(
          bottom: Gap.x16,
          left: Spacing.screen,
          right: Spacing.screen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark().inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsDark().border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsDark().border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: AppColorsDark().primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.block,
          vertical: Spacing.block,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: text.body.copyWith(color: AppColorsDark().textMedium),
        floatingLabelStyle: text.body.copyWith(
          color: AppColorsDark().primaryLight,
        ),
        hintStyle: text.body.copyWith(color: AppColorsDark().textLight),
      ),
      dividerTheme: DividerThemeData(
        color: AppColorsDark().divider,
        thickness: 1,
        space: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark().green;
          }
          return Colors.transparent;
        }),
        shape: const CircleBorder(),
        side: BorderSide(color: AppColorsDark().border, width: 2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColorsDark().primary,
        inactiveTrackColor: AppColorsDark().insetSurface,
        trackHeight: 6,
        thumbColor: AppColorsDark().primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark().card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.screenTitle.copyWith(
          color: AppColorsDark().textDark,
        ),
        contentTextStyle: text.body.copyWith(color: AppColorsDark().textMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.body.copyWith(color: AppColorsDark().textDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColorsDark().card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyStrong.copyWith(
          color: AppColorsDark().textDark,
        ),
        subtitleTextStyle: text.caption.copyWith(
          color: AppColorsDark().textMedium,
        ),
        iconColor: AppColorsDark().textMedium,
      ),
      canvasColor: AppColorsDark().card,
      popupMenuTheme: PopupMenuThemeData(
        color: AppColorsDark().card,
        textStyle: text.body.copyWith(color: AppColorsDark().textDark),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color textDark,
    required Color textMedium,
    required Color textLight,
    required Color primary,
    required AppTypography text,
  }) {
    final metric = text.metric.copyWith(color: textDark);
    final display = text.display.copyWith(color: textDark);
    final screenTitle = text.screenTitle.copyWith(color: textDark);
    final cardTitle = text.cardTitle.copyWith(color: textDark);
    final sectionLabel = text.bodyStrong.copyWith(color: primary);
    final eyebrow = text.micro.copyWith(color: textMedium);
    final body = text.body.copyWith(color: textDark);
    final bodyStrong = text.bodyStrong.copyWith(color: textDark);
    final caption = text.caption.copyWith(color: textMedium);
    final micro = text.micro.copyWith(color: textMedium);

    return TextTheme(
      displayLarge: metric,
      displayMedium: display,
      displaySmall: screenTitle,
      headlineLarge: display,
      headlineMedium: screenTitle,
      headlineSmall: cardTitle,
      titleLarge: cardTitle,
      titleMedium: bodyStrong,
      titleSmall: caption,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: bodyStrong,
      labelMedium: caption,
      labelSmall: micro,
    ).apply(bodyColor: textDark, displayColor: textDark);
  }
}
