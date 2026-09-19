import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/rest_timer_bar.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('General Sans');
    for (final name in [
      'GeneralSans-Medium',
      'GeneralSans-Semibold',
      'GeneralSans-Bold',
    ]) {
      fonts.addFont(rootBundle.load('assets/fonts/$name.ttf'));
    }
    await fonts.load();
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'rest timer fits $width px at ${scale}x text and keeps controls usable',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final additions = <int>[];
          var toggled = false;
          var closed = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 700),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: RestTimerBar(
                        remainingSeconds: 125,
                        isPaused: false,
                        exerciseName: 'Long alternating dumbbell exercise name',
                        onAddSeconds: additions.add,
                        onTogglePause: () => toggled = true,
                        onClose: () => closed = true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('2:05'), findsOneWidget);
          await tester.tap(find.text('+15s'));
          await tester.tap(find.text('+30s'));
          await tester.tap(find.byTooltip('Pause timer'));
          await tester.tap(find.byTooltip('Close timer'));
          expect(additions, [15, 30]);
          expect(toggled, isTrue);
          expect(closed, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'rest timer controls and caption have contrast in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: RestTimerBar(
                  remainingSeconds: 125,
                  isPaused: false,
                  onAddSeconds: (_) {},
                  onTogglePause: () {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        );
        final fill = (dark ? AppColors.dark : AppColors.light).orange;
        for (final label in ['Rest timer', '2:05', '+15s', '+30s']) {
          final rendered = tester.widget<RichText>(
            find.descendant(
              of: find.text(label),
              matching: find.byType(RichText),
            ),
          );
          expect(
            _contrast(rendered.text.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$label should be readable on the timer fill.',
          );
        }
        for (final tooltip in ['Pause timer', 'Close timer']) {
          final button = tester.widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip(tooltip),
                  matching: find.byType(IconButton),
                )
                .first,
          );
          expect(_contrast(button.color!, fill), greaterThanOrEqualTo(3));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'paused timer exposes complete exercise and remaining time without live ticks',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        const exercise = 'Long alternating dumbbell exercise name';
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: RestTimerBar(
                remainingSeconds: 125,
                isPaused: true,
                exerciseName: exercise,
                onAddSeconds: (_) {},
                onTogglePause: () {},
                onClose: () {},
              ),
            ),
          ),
        );
        expect(find.text('Rest paused'), findsOneWidget);
        expect(find.byTooltip('Rest paused for $exercise'), findsOneWidget);
        expect(find.byTooltip('Resume timer'), findsOneWidget);
        final summary = tester.getSemantics(
          find.byKey(const ValueKey('rest-timer-summary')),
        );
        expect(summary.label, 'Rest timer, paused for $exercise');
        expect(summary.value, '2 minutes 5 seconds remaining');
        expect(
          summary.getSemanticsData().flagsCollection.isLiveRegion,
          isFalse,
        );
        expect(find.byTooltip('Close timer'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    },
  );
}
