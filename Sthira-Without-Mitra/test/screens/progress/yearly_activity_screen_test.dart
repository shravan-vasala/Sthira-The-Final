import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/models/yearly_activity.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/progress/yearly_activity_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _today = DateTime(2026, 9, 19);
final _initialDate = DateTime(2026, 8, 1);
const _captureRoot = Key('heatmap-capture-root');
const _captureDirectory = String.fromEnvironment('HEATMAP_CAPTURE');

YearlyActivity _activity(int year, {bool empty = false}) => YearlyActivity(
  year: year,
  today: _today,
  days: empty
      ? {}
      : {
          DateTime(year, 9, 14): ActivityDay(
            date: DateTime(year, 9, 14),
            areas: {ActivityArea.wellbeing},
          ),
          DateTime(year, 9, 15): ActivityDay(
            date: DateTime(year, 9, 15),
            areas: {ActivityArea.meals, ActivityArea.habits},
          ),
          DateTime(year, 9, 18): ActivityDay(
            date: DateTime(year, 9, 18),
            areas: {ActivityArea.workouts},
            workoutStatus: 'partial',
          ),
        },
);

// Populated preview data is deliberately isolated from behavior-test fixtures.
// Color reflects which areas were recorded, never a score or goal result.
YearlyActivity _denseActivity(int year) {
  const patterns = <Set<ActivityArea>>[
    {ActivityArea.meals, ActivityArea.wellbeing},
    {},
    {ActivityArea.meals, ActivityArea.habits},
    {ActivityArea.wellbeing},
    {ActivityArea.meals, ActivityArea.habits, ActivityArea.workouts},
    {},
    {
      ActivityArea.meals,
      ActivityArea.habits,
      ActivityArea.workouts,
      ActivityArea.wellbeing,
    },
  ];
  final days = <DateTime, ActivityDay>{};
  for (var index = 0; index < 366; index++) {
    final date = DateTime(year, 1, index + 1);
    if (date.year != year || date.isAfter(_today)) break;
    final areas = patterns[(index + index ~/ 7) % patterns.length];
    if (areas.isEmpty) continue;
    days[date] = ActivityDay(
      date: date,
      areas: areas,
      workoutStatus: areas.contains(ActivityArea.workouts)
          ? index % 3 == 0
                ? 'partial'
                : 'completed'
          : null,
    );
  }
  return YearlyActivity(year: year, today: _today, days: days);
}

class _Harness {
  const _Harness(this.container, this.router);
  final ProviderContainer container;
  final GoRouter router;
}

Future<_Harness> _show(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  bool dark = false,
  bool empty = false,
  Future<YearlyActivity> Function(int year)? load,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(_today),
      selectedDateProvider.overrideWith((ref) => _initialDate),
      weekOffsetProvider.overrideWith((ref) => -7),
      selectedYearProvider.overrideWith((ref) => _today.year),
      yearlyActivityHeatmapProvider.overrideWith(
        (ref, year) =>
            load?.call(year) ?? Future.value(_activity(year, empty: empty)),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/progress/yearly-activity',
    routes: [
      GoRoute(
        path: '/progress/yearly-activity',
        builder: (_, _) => const YearlyActivityScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home day')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: _captureRoot,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, router);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSeptember(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('heatmap-month-9')));
  expect(find.byKey(const ValueKey('heatmap-month-detail')), findsOneWidget);
  expect(find.text('September 2026'), findsOneWidget);
}

void _expectWholeSeptemberDateLabels(WidgetTester tester) {
  for (var day = 1; day <= 30; day++) {
    final date = '2026-09-${day.toString().padLeft(2, '0')}';
    final label = find.descendant(
      of: find.byKey(ValueKey('heatmap-day-$date')),
      matching: find.text('$day'),
    );
    expect(label, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(label);
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason:
          'The full date number for $date must fit at the system text size.',
    );
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  expect(tester.takeException(), isNull);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureRoot),
  );
  await tester.runAsync(() async {
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    bitmap.dispose();
    final directory = Directory(_captureDirectory);
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png').writeAsBytes(
      png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final entry in {
      'Cabinet Grotesk': [
        'CabinetGrotesk-Regular.ttf',
        'CabinetGrotesk-Medium.ttf',
        'CabinetGrotesk-Bold.ttf',
        'CabinetGrotesk-Extrabold.ttf',
        'CabinetGrotesk-Black.ttf',
      ],
      'General Sans': [
        'GeneralSans-Regular.ttf',
        'GeneralSans-Medium.ttf',
        'GeneralSans-Semibold.ttf',
        'GeneralSans-Bold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final font in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$font'));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets(
    'year overview counts recorded days and keeps all months available',
    (tester) async {
      await _show(tester);
      expect(
        find.byKey(const ValueKey('heatmap-recorded-days')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('heatmap-recorded-days')),
          matching: find.text('3'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      for (var month = 1; month <= 12; month++) {
        expect(find.byKey(ValueKey('heatmap-month-$month')), findsOneWidget);
      }
      // Keep the annual pattern above statistics and the floating navigation.
      expect(
        tester
            .getBottomRight(find.byKey(const ValueKey('heatmap-month-12')))
            .dy,
        lessThanOrEqualTo(744),
      );
      expect(find.textContaining('missed goals'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'month and date inspection preserve the home date until View day',
    (tester) async {
      final harness = await _show(tester);
      await _openSeptember(tester);
      expect(harness.container.read(selectedDateProvider), _initialDate);
      expect(harness.container.read(weekOffsetProvider), -7);
      expect(find.text('Home day'), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('heatmap-day-2026-09-14')));
      expect(harness.container.read(selectedDateProvider), _initialDate);
      expect(harness.container.read(weekOffsetProvider), -7);
      expect(
        find.byKey(const ValueKey('heatmap-month-detail')),
        findsOneWidget,
      );
      expect(find.text('Home day'), findsNothing);

      await _tap(tester, find.text('View day'));
      expect(
        harness.container.read(selectedDateProvider),
        DateTime(2026, 9, 14),
      );
      expect(harness.container.read(weekOffsetProvider), 0);
      expect(find.text('Home day'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'future dates are disabled and cannot replace the inspected date',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final harness = await _show(tester);
        await _openSeptember(tester);
        await _tap(
          tester,
          find.byKey(const ValueKey('heatmap-day-2026-09-14')),
        );
        final future = find.byKey(const ValueKey('heatmap-day-2026-09-20'));
        final data = tester.getSemantics(future).getSemanticsData();
        expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
        await _tap(tester, future);
        await _tap(tester, find.text('View day'));
        expect(
          harness.container.read(selectedDateProvider),
          DateTime(2026, 9, 14),
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'year navigation can return to this year but cannot go beyond it',
    (tester) async {
      final harness = await _show(tester);
      expect(harness.container.read(selectedYearProvider), 2026);
      expect(
        tester
            .widget<IconButton>(
              find
                  .ancestor(
                    of: find.byTooltip('Next year'),
                    matching: find.byType(IconButton),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byTooltip('Previous year'));
      expect(harness.container.read(selectedYearProvider), 2025);
      await _tap(tester, find.byTooltip('Next year'));
      expect(harness.container.read(selectedYearProvider), 2026);
      expect(
        tester
            .widget<IconButton>(
              find
                  .ancestor(
                    of: find.byTooltip('Next year'),
                    matching: find.byType(IconButton),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an empty year stays neutral and dates remain inspectable', (
    tester,
  ) async {
    await _show(tester, empty: true);
    expect(find.textContaining('missed goals'), findsNothing);
    expect(find.textContaining('failure'), findsNothing);
    expect(find.byKey(const ValueKey('heatmap-recorded-days')), findsOneWidget);
    await _openSeptember(tester);
    await _tap(tester, find.byKey(const ValueKey('heatmap-day-2026-09-14')));
    expect(find.text('View day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed year loading offers retry and recovers to the overview', (
    tester,
  ) async {
    var attempts = 0;
    await _show(
      tester,
      load: (year) async {
        attempts++;
        if (attempts == 1) throw StateError('offline test fixture');
        return _activity(year);
      },
    );
    expect(find.text('Retry'), findsOneWidget);
    await _tap(tester, find.text('Retry'));
    expect(attempts, 2);
    expect(find.byKey(const ValueKey('heatmap-recorded-days')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dense year keeps twelve months visible', (tester) async {
    for (final dark in [false, true]) {
      await _show(
        tester,
        dark: dark,
        load: (year) async => _denseActivity(year),
      );
      try {
        for (var month = 1; month <= 12; month++) {
          expect(find.byKey(ValueKey('heatmap-month-$month')), findsOneWidget);
        }
        expect(
          tester
              .getBottomRight(find.byKey(const ValueKey('heatmap-month-12')))
              .dy,
          lessThanOrEqualTo(744),
        );
        expect(tester.takeException(), isNull);
        await _capture(tester, 'year-dense-390-1x-${dark ? 'dark' : 'light'}');
      } finally {
        // Each theme owns a separate provider container. Unmount and drain its
        // auto-dispose work before replacing it or ending the widget test.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    }
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        final name =
            '${width.toInt()}-${scale.toInt()}x-${dark ? 'dark' : 'light'}';
        testWidgets('year and month remain usable at $name', (tester) async {
          await _show(tester, width: width, textScale: scale, dark: dark);
          expect(tester.takeException(), isNull);
          await _capture(tester, 'year-$name');
          for (final month in [1, 6, 12]) {
            await tester.ensureVisible(
              find.byKey(ValueKey('heatmap-month-$month')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await _openSeptember(tester);
          _expectWholeSeptemberDateLabels(tester);
          await _tap(
            tester,
            find.byKey(const ValueKey('heatmap-day-2026-09-14')),
          );
          await tester.ensureVisible(find.text('View day'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('View day').hitTestable(), findsOneWidget);
          await _capture(tester, 'month-$name');
        });
      }
    }
  }
}
