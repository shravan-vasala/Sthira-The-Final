import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/theme/layout_insets.dart';
import 'package:trufit_bodamma/widgets/app_navigation_bar.dart';
import 'package:trufit_bodamma/widgets/rest_timer_bar.dart';

Widget _timer() => RestTimerBar(
  remainingSeconds: 75,
  isPaused: false,
  exerciseName: 'Dumbbell rows',
  onAddSeconds: (_) {},
  onTogglePause: () {},
  onClose: () {},
);

Widget _app({
  required GlobalKey<ScaffoldMessengerState> messenger,
  double width = 390,
  double scale = 1,
  bool dark = false,
  bool timer = true,
  double keyboard = 0,
  ValueChanged<int>? onSelect,
}) => MaterialApp(
  scaffoldMessengerKey: messenger,
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 24, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
      viewInsets: EdgeInsets.only(bottom: keyboard),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(
    extendBody: true,
    body: Builder(
      builder: (context) => Scaffold(
        body: ListView(
          padding: EdgeInsets.only(bottom: shellScrollBottomPadding(context)),
          children: [
            for (var i = 0; i < 20; i++)
              SizedBox(height: 60, child: Text('Entry $i')),
            const SizedBox(height: 48, child: Text('Last entry')),
          ],
        ),
      ),
    ),
    bottomNavigationBar: AppNavigationDock(
      currentIndex: 0,
      onItemSelected: onSelect ?? (_) {},
      restTimer: timer ? _timer() : null,
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 390.0]) {
        testWidgets(
          'footer and feedback clear each other at $width / $scale / dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final messenger = GlobalKey<ScaffoldMessengerState>();
            await tester.pumpWidget(
              _app(
                messenger: messenger,
                width: width,
                scale: scale,
                dark: dark,
              ),
            );
            final nav = tester.getRect(find.byType(AppNavigationBar));
            final timer = tester.getRect(find.byType(RestTimerBar));
            expect(timer.bottom, lessThan(nav.top));
            expect(nav.bottom, lessThanOrEqualTo(844 - 34));
            for (final label in ['Home', 'Progress', 'Social', 'Profile']) {
              expect(find.text(label), findsOneWidget);
              final target = tester.getSize(
                find.byKey(ValueKey('nav-${label.toLowerCase()}')),
              );
              expect(target.width, greaterThanOrEqualTo(48));
              expect(target.height, greaterThanOrEqualTo(48));
            }
            await tester.dragFrom(
              Offset(width / 2, 180),
              const Offset(0, -1800),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getRect(find.text('Last entry')).bottom,
              lessThan(timer.top),
            );
            messenger.currentState!.showSnackBar(
              SnackBar(
                content: const Text('Meal removed'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getRect(find.byType(SnackBar)).bottom,
              lessThanOrEqualTo(timer.top),
            );
            expect(find.text('Undo'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  testWidgets(
    'destinations announce selection, do not shift, and ignore reselection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <int>[];
      await tester.pumpWidget(
        _app(
          messenger: GlobalKey<ScaffoldMessengerState>(),
          timer: false,
          onSelect: calls.add,
        ),
      );
      final home = find.byKey(const ValueKey('nav-home'));
      final progress = find.byKey(const ValueKey('nav-progress'));
      final node = tester.getSemantics(home);
      expect(node.label, 'Home');
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      final before = tester.getRect(progress);
      await tester.tap(home);
      await tester.tap(progress);
      await tester.pumpAndSettle();
      expect(calls, [1]);
      expect(tester.getRect(progress), before);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('navigation can be activated with the keyboard', (tester) async {
    final calls = <int>[];
    await tester.pumpWidget(
      _app(
        messenger: GlobalKey<ScaffoldMessengerState>(),
        timer: false,
        onSelect: calls.add,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, [1]);
  });

  testWidgets(
    'typing makes room for the editor and footer returns afterwards',
    (tester) async {
      final messenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(_app(messenger: messenger, keyboard: 300));
      expect(find.byType(AppNavigationBar), findsNothing);
      expect(find.byType(RestTimerBar), findsNothing);
      await tester.pumpWidget(_app(messenger: messenger));
      expect(find.byType(AppNavigationBar), findsOneWidget);
      expect(find.text('1:15'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'full-screen toast stays near the bottom and keeps Undo accessible',
    (tester) async {
      final messenger = GlobalKey<ScaffoldMessengerState>();
      var undone = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          scaffoldMessengerKey: messenger,
          home: const Scaffold(body: Text('Meal detail')),
        ),
      );
      messenger.currentState!.showSnackBar(
        SnackBar(
          content: const Text('Meal removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => undone = true),
        ),
      );
      await tester.pumpAndSettle();
      final viewport =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        viewport - tester.getRect(find.byType(SnackBar)).bottom,
        lessThan(40),
      );
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
