import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/welcome_page.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/gita_verse_sheet.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'General Sans': ['GeneralSans-Regular.ttf', 'GeneralSans-Semibold.ttf'],
      'Cabinet Grotesk': ['CabinetGrotesk-Extrabold.ttf'],
      'Caveat': ['Caveat-Regular.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });

  Widget app(Widget child, {bool dark = false, double scale = 1}) =>
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(body: child),
      );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'reflection is readable and dismissible with real fonts dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              app(
                const Center(child: GitaReflectionButton()),
                dark: dark,
                scale: scale,
              ),
            );
            final action = find.byType(TextButton);
            final size = tester.getSize(action);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
            final node = tester.getSemantics(action);
            expect(node.label, contains('Bhagavad Gita reflection'));
            expect(node.hasFlag(ui.SemanticsFlag.isButton), isTrue);
            expect(
              node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
              isTrue,
            );
            final reference = tester.widget<Text>(find.text('2:47'));
            expect(
              reference.style!.color,
              dark ? AppColors.dark.accentText : AppColors.light.accentText,
            );
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(find.byType(GitaVerseSheet), findsOneWidget);
            expect(tester.takeException(), isNull);
            final quote = tester.widget<Text>(
              find.textContaining('Krishna does not ask'),
            );
            expect(quote.style!.fontFamily, 'Caveat');
            final scrollable = find.descendant(
              of: find.byType(GitaVerseSheet),
              matching: find.byType(Scrollable),
            );
            final state = tester.state<ScrollableState>(scrollable);
            state.position.jumpTo(state.position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(state.position.extentAfter, 0);
            expect(tester.takeException(), isNull);
            await tester.tapAt(const Offset(8, 8));
            await tester.pumpAndSettle();
            expect(find.byType(GitaVerseSheet), findsNothing);
            expect(find.byType(GitaReflectionButton), findsOneWidget);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('onboarding uses the named focusable reflection action', (
    tester,
  ) async {
    await tester.pumpWidget(app(const WelcomePage()));
    await tester.pumpAndSettle();
    final action = find.descendant(
      of: find.byType(GitaReflectionButton),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    final focus = Focus.of(tester.element(find.text('2:47')));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(GitaVerseSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GitaVerseSheet), findsNothing);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
