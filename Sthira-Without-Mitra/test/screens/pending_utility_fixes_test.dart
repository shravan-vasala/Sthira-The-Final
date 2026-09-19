import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/body_stats.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/body_stats_repository.dart';
import 'package:trufit_bodamma/screens/home/body_stats_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/numeric_entry_sheet.dart';

class _StatsRepo extends BodyStatsRepository {
  BodyStats? saved;
  _StatsRepo(this.saved);
  @override
  BodyStats? getStats(String date) => saved?.date == date ? saved : null;
  @override
  BodyStats? getLatestStats() => saved;
  @override
  Future<void> saveStats(BodyStats stats) async => saved = stats;
}

void main() {
  testWidgets('numeric save prevents duplicates and preserves failed entries', (
    tester,
  ) async {
    final controller = TextEditingController(text: '72.5');
    addTearDown(controller.dispose);
    var saves = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NumericEntrySheet(
            title: 'Weight',
            saveLabel: 'Save weight',
            controller: controller,
            autofocus: false,
            onSave: () {
              saves++;
              return saves == 1 ? pending.future : Future<void>.value();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save weight'));
    await tester.pump();
    await tester.tap(find.text('Save weight'));
    expect(saves, 1);
    pending.completeError(StateError('test write failure'));
    await tester.pumpAndSettle();
    expect(controller.text, '72.5');
    expect(
      find.text('Could not save. Your entry is kept. Try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'body measurements reject invalid input and preserve imported units',
    (tester) async {
      final original = BodyStats(date: '2026-09-19', waist: 32, unit: 'inches');
      final repo = _StatsRepo(original);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bodyStatsRepoProvider.overrideWithValue(repo),
            dateStringProvider.overrideWithValue('2026-09-19'),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const BodyStatsScreen(),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('body-stat-Waist'));
      await tester.enterText(field, '-8');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(identical(repo.saved, original), isTrue);
      expect(find.text('Enter a positive measurement.'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, '-8');
      await tester.enterText(field, '31.5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.saved!.waist, 31.5);
      expect(repo.saved!.unit, 'inches');
    },
  );

  testWidgets('body measurements fit narrow screens at enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _StatsRepo(
      BodyStats(date: '2026-09-19', waist: 125.5, rightThigh: 65.5),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bodyStatsRepoProvider.overrideWithValue(repo),
          dateStringProvider.overrideWithValue('2026-09-19'),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const BodyStatsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
