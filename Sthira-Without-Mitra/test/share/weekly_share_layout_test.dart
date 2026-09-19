import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/share/share_card_exporter.dart';
import 'package:trufit_bodamma/share/weekly_share_layout.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

Future<void> _show(
  WidgetTester tester,
  ShareFormat format, {
  bool recorded = true,
}) async {
  tester.view.physicalSize = Size(360, format == ShareFormat.story ? 640 : 450);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: WeeklyShareLayout(
          format: format,
          userName: 'Alex',
          dateRange: '14–20 Sep 2026',
          weekScore: 0,
          prevWeekScore: null,
          dailyScores: recorded ? [0, null, null, null, null, null, null] : [],
          workoutsCompleted: 0,
          workoutsTotal: 0,
          avgSteps: 0,
          habitCompletionPercent: recorded ? 0 : null,
          baseColor: Colors.green,
          stepsDays: recorded ? 1 : 0,
          scoreDays: recorded ? 1 : 0,
          elapsedDays: 2,
          scheduledHabitInstances: 4,
          recordedHabitInstances: recorded ? 1 : 0,
          isPartialWeek: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final format in ShareFormat.values) {
    testWidgets(
      '${format.name} export fits its canvas and preserves zero vs missing data',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _show(tester, format);
          expect(tester.takeException(), isNull);
          expect(find.text('0 / 100'), findsOneWidget);
          expect(
            find.text('Week in progress · 1 of 2 days scored'),
            findsOneWidget,
          );
          expect(find.text('0%'), findsOneWidget);
          expect(find.text('1/4 recorded'), findsOneWidget);
          expect(find.text('0'), findsOneWidget);
          final zero = tester.widget<Container>(
            find.byKey(const ValueKey('weekly-share-bar-0')),
          );
          final missing = tester.widget<Container>(
            find.byKey(const ValueKey('weekly-share-bar-1')),
          );
          expect(zero.child, isNotNull);
          expect(missing.child, isNull);
          expect(
            tester.getSize(find.byWidget(zero.child!)).height,
            greaterThanOrEqualTo(2),
          );
          expect(find.bySemanticsLabel('Monday, 0 of 100'), findsOneWidget);
          expect(find.bySemanticsLabel('Tuesday, unscored'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets(
    'no records produce neutral share values instead of failed scores',
    (tester) async {
      await _show(tester, ShareFormat.post, recorded: false);
      expect(find.text('0 / 100'), findsNothing);
      expect(find.text('0%'), findsNothing);
      expect(find.text('No entries'), findsNWidgets(2));
      expect(
        find.text('Week in progress · 0 of 2 days scored'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
