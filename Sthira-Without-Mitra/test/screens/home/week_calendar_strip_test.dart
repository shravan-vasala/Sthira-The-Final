import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widgets/week_calendar_strip.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _now = DateTime(2026, 9, 19);
DailyScore _score() => DailyScore(
  totalScore: 75,
  isFutureDate: false,
  habitsScore: 30,
  habitsMax: 40,
  workoutsScore: 30,
  workoutsMax: 40,
  mealsScore: 15,
  mealsMax: 20,
  totalMax: 100,
  date: _now,
);

Widget _app({
  double scale = 1,
  bool dark = true,
  bool disableAnimations = true,
  GlobalKey? capture,
  DateTime Function()? clock,
}) => ProviderScope(
  overrides: [
    clockProvider.overrideWith((ref) => clock?.call() ?? _now),
    selectedDateProvider.overrideWith((ref) => _now),
    dailyScoreProvider.overrideWithValue(_score()),
    calendarWeekActivityProvider.overrideWith(
      (ref, week) => {'2026-09-20': true},
    ),
  ],
  child: MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: RepaintBoundary(key: capture, child: const WeekCalendarStrip()),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    for (final entry in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'General Sans': 'assets/fonts/GeneralSans-Medium.ttf',
      'Cabinet Grotesk': 'assets/fonts/CabinetGrotesk-Bold.ttf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load(entry.value));
      await loader.load();
    }
  });

  for (final dark in [true, false]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('calendar fits 320px, $scale text, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final capture = GlobalKey();
        await tester.pumpWidget(
          _app(scale: scale, dark: dark, capture: capture),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var day = 14; day <= 20; day++) {
          expect(find.text('$day'), findsOneWidget);
          final rect = tester.getRect(find.text('$day'));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        final directory = const String.fromEnvironment('CALENDAR_CAPTURE');
        if (directory.isNotEmpty) {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(directory).create(recursive: true);
            await File(
              '$directory/calendar-${dark ? 'dark' : 'light'}-$scale.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  testWidgets(
    'navigation follows visible week and Today resets date and week',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WeekCalendarStrip)),
      );
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      expect(find.text('7–13 Sep'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      // Browsing weeks preserves the selected day until the user chooses a day.
      expect(container.read(selectedDateProvider), _now);
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 8));
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(container.read(selectedDateProvider), _now);
      expect(container.read(weekOffsetProvider), 0);
      expect(find.text('This week'), findsOneWidget);
    },
  );

  testWidgets(
    'external selection moves calendar and year context stays visible',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WeekCalendarStrip)),
      );
      container.read(selectedDateProvider.notifier).state = DateTime(
        2025,
        12,
        30,
      );
      await tester.pumpAndSettle();
      expect(find.text('29 Dec 2025 – 4 Jan 2026'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Monday rollover preserves selected past date and visible week', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 20);
    await tester.pumpWidget(_app(clock: () => now));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeekCalendarStrip)),
    );
    now = DateTime(2026, 9, 21);
    container.invalidate(clockProvider);
    await tester.pumpAndSettle();
    expect(container.read(weekOffsetProvider), -1);
    expect(find.text('14–20 Sep'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping browses a week without changing the selected date', (
    tester,
  ) async {
    await tester.pumpWidget(_app(disableAnimations: false));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WeekCalendarStrip)),
    );
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(container.read(weekOffsetProvider), 1);
    expect(container.read(selectedDateProvider), _now);
    expect(find.text('21–27 Sep'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest-day entries have honest activity semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Sunday, September 20, 2026, Activity logged'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Activity completed')), findsNothing);
    expect(
      find.bySemanticsLabel('Daily score for Sep 19, 2026: 75 out of 100'),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.bySemanticsLabel(
              'Sunday, September 20, 2026, Activity logged',
            ),
          )
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(
            find.bySemanticsLabel(
              'Daily score for Sep 19, 2026: 75 out of 100',
            ),
          )
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
}
