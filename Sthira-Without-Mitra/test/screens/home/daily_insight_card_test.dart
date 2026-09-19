import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/insight.dart';
import 'package:trufit_bodamma/providers/insights_provider.dart';
import 'package:trufit_bodamma/screens/home/widgets/daily_insight_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'recent insight preserves evidence context at 320px and 200 percent in ${dark ? "dark" : "light"}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final description =
            'Paired logs from 20 Aug–18 Sep 2026 show an average of 9,000 steps after 7.5h+ sleep (5 days), versus 6,000 after shorter sleep (5 days). Other factors may contribute.';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              insightsProvider.overrideWithValue([
                Insight(
                  id: 'corr_sleep_steps',
                  type: InsightType.correlation,
                  title: 'Sleep and recorded steps',
                  description: description,
                  severity: InsightSeverity.neutral,
                  dateGenerated: DateTime(2026, 9, 19),
                  icon: Icons.bedtime_rounded,
                ),
              ]),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(child: DailyInsightCard()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('RECENT INSIGHT'), findsOneWidget);
        expect(find.text(description), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
