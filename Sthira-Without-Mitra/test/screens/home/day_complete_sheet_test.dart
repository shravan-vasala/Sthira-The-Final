import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widgets/day_complete_sheet.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alexandra Catherine Vasala');
}

DailyScore _score({bool complete = true, bool planned = true}) => DailyScore(
  totalScore: complete ? 100 : 50,
  isFutureDate: false,
  habitsScore: complete ? 40 : 0,
  habitsMax: planned ? 40 : 0,
  workoutsScore: 30,
  workoutsMax: planned ? 30 : 0,
  mealsScore: 30,
  mealsMax: planned ? 30 : 0,
  totalMax: 100,
);

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  double textScale = 1,
  String date = '2026-09-19',
  bool complete = true,
  bool planned = true,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(_Profile.new),
      clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
      dateStringProvider.overrideWithValue(date),
      dailyScoreProvider.overrideWithValue(
        _score(complete: complete, planned: planned),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: DayCompleteAction(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'completed day is optional and opens a readable summary at 320px and 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, textScale: 2);
      expect(find.byType(DayCompleteSheet), findsNothing);
      expect(tester.takeException(), isNull);
      final action = find.widgetWithText(
        TextButton,
        'Day complete · View summary',
      );
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Day complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(DayCompleteSheet), findsNothing);
    },
  );

  testWidgets(
    'completion summary is not offered for an incomplete or historical day',
    (tester) async {
      await _mount(tester, complete: false);
      expect(find.text('Day complete · View summary'), findsNothing);
      await _mount(tester, date: '2026-09-18');
      expect(find.text('Day complete · View summary'), findsNothing);
    },
  );

  testWidgets('steps-only score never offers primary day completion', (
    tester,
  ) async {
    await _mount(tester, planned: false);
    expect(find.text('Day complete · View summary'), findsNothing);
    expect(find.byType(DayCompleteSheet), findsNothing);
  });

  testWidgets(
    'account switch removes a covered completion sheet without popping the covering route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final container = await _mount(tester, navigatorKey: navigator);
      await tester.tap(find.text('Day complete · View summary'));
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering route')),
        ),
      );
      await tester.pumpAndSettle();
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(find.text('Covering route'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DayCompleteSheet), findsNothing);
      expect(find.text('Day complete'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
