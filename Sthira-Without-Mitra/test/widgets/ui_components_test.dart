import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/screens/home/widgets/home_greeting.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/widgets/app_text_field.dart';
import 'package:trufit_bodamma/widgets/primary_button.dart';
import 'package:trufit_bodamma/widgets/section_header.dart';
import 'package:trufit_bodamma/widgets/settings_row.dart';
import 'package:trufit_bodamma/widgets/surface_card.dart';

Widget _app(
  Widget child, {
  bool dark = true,
  double scale = 1,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Actions and headings fit 320px, dark=$dark scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var taps = 0;
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                SectionHeader(
                  'Daily progress and recovery',
                  horizontalPadding: 0,
                  countLabel: const Text('3/5'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit goals',
                    onPressed: () => taps++,
                  ),
                ),
                PrimaryButton(
                  label: 'Save meal and continue',
                  icon: Icons.check,
                  onPressed: () => taps++,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CompactButton(
                        label: 'Take photo',
                        icon: Icons.camera_alt_outlined,
                        filled: true,
                        onPressed: () => taps++,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CompactButton(
                        label: 'Describe meal',
                        icon: Icons.edit_outlined,
                        onPressed: () => taps++,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            dark: dark,
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byTooltip('Edit goals')).shortestSide,
          greaterThanOrEqualTo(48),
        );
        for (final button in find.byType(CompactButton).evaluate()) {
          expect(
            tester.getSize(find.byWidget(button.widget)).height,
            greaterThanOrEqualTo(48),
          );
        }
        await tester.tap(find.byTooltip('Edit goals'));
        await tester.tap(find.text('Save meal and continue'));
        expect(taps, 2);
      });
    }
  }

  testWidgets(
    'Filled, outlined and disabled labels inherit their action colors',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              CompactButton(label: 'Filled', filled: true, onPressed: () {}),
              CompactButton(label: 'Outlined', onPressed: () {}),
              const PrimaryButton(label: 'Disabled', onPressed: null),
            ],
          ),
          dark: false,
        ),
      );
      Color? colorFor(String text) {
        final rich = tester.widget<RichText>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        );
        return rich.text.style?.color;
      }

      expect(colorFor('Filled'), AppColors.light.onPrimary);
      expect(colorFor('Outlined'), AppColors.light.indigo);
      expect(colorFor('Disabled'), AppColors.light.textMedium);
    },
  );

  testWidgets(
    'Loading keeps its label, announces progress, and prevents a second action',
    (tester) async {
      final semantics = tester.ensureSemantics();

      var taps = 0;
      await tester.pumpWidget(
        _app(
          PrimaryButton(
            label: 'Save meal',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.text('Save meal'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Save meal'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Save meal'));
      expect(node.value, 'In progress');
      expect(node.hasFlag(ui.SemanticsFlag.isLiveRegion), isTrue);
      expect(node.hasFlag(ui.SemanticsFlag.isEnabled), isFalse);
      await tester.tap(find.text('Save meal'));
      expect(taps, 0);
      semantics.dispose();
    },
  );

  testWidgets(
    'Button press feedback respects reduced motion and cancellation',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          CompactButton(label: 'Photo', onPressed: () => taps++),
          reduceMotion: true,
        ),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.text('Photo')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await press.cancel();
      await tester.pumpAndSettle();
      expect(taps, 0);
      await tester.tap(find.text('Photo'));
      expect(taps, 1);
    },
  );

  if (const bool.fromEnvironment('UI_PREVIEW')) {
    testWidgets('Render actual shared components with bundled brand fonts', (
      tester,
    ) async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final entry in {
        'Cabinet Grotesk': ['CabinetGrotesk-Bold', 'CabinetGrotesk-Extrabold'],
        'General Sans': [
          'GeneralSans-Medium',
          'GeneralSans-Semibold',
          'GeneralSans-Bold',
        ],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final font in entry.value) {
          loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
        }
        await loader.load();
      }
      tester.view.physicalSize = const Size(390, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController(text: 'Evening meal');
      addTearDown(controller.dispose);
      for (final dark in [true, false]) {
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: RepaintBoundary(
              key: capture,
              child: Scaffold(
                body: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeGreetingContent(
                          name: 'Alex',
                          selectedDate: DateTime(2026, 9, 19),
                          now: DateTime(2026, 9, 19, 10),
                          onReturnToToday: () {},
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          'Meals',
                          horizontalPadding: 0,
                          trailing: IconButton(
                            tooltip: 'Edit meals',
                            onPressed: () {},
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SurfaceCard(
                          margin: EdgeInsets.zero,
                          onTap: () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's meals",
                                style: context.text.cardTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '2/4 meals \u00b7 840/1800 kcal',
                                style: context.text.caption,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CompactButton(
                                      label: 'Photo',
                                      icon: Icons.camera_alt_outlined,
                                      filled: true,
                                      onPressed: () {},
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CompactButton(
                                      label: 'Describe',
                                      icon: Icons.edit_outlined,
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: controller,
                          labelText: 'Meal name',
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Save meal',
                          icon: Icons.check_rounded,
                          onPressed: () {},
                        ),
                        const SizedBox(height: 12),
                        const PrimaryButton(
                          label: 'Save meal',
                          onPressed: null,
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader(
                          'Your preferences',
                          horizontalPadding: 0,
                        ),
                        const SizedBox(height: 12),
                        SettingsRow(
                          title: 'Reminders',
                          subtitle: 'A little nudge, at the right time',
                          icon: Icons.notifications_none_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final path =
              'build/ui-review/components-${dark ? 'dark' : 'light'}.png';
          await File(path).parent.create(recursive: true);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
