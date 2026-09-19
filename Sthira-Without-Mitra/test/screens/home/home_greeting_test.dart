import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/midnight_tick_provider.dart';
import 'package:trufit_bodamma/screens/home/widgets/home_greeting.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alex');
  void replaceProfile(UserProfile profile) => state = profile;
}

class _NoMidnightTick extends MidnightTickNotifier {
  @override
  void build() {}
}

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: child,
    ),
  ),
);

Widget _connectedGreeting(DateTime Function() clock, DateTime selectedDate) =>
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(_Profile.new),
        midnightTickProvider.overrideWith(_NoMidnightTick.new),
        selectedDateProvider.overrideWith((ref) => selectedDate),
        weekOffsetProvider.overrideWith((ref) => -3),
      ],
      child: _app(HomeGreeting(clock: clock)),
    );

void main() {
  testWidgets(
    'avatar opens profile without truncating a long greeting at 320px and 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime(2026, 9, 19, 10);
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(_Profile.new),
          midnightTickProvider.overrideWith(_NoMidnightTick.new),
          selectedDateProvider.overrideWith((ref) => now),
        ],
      );
      addTearDown(container.dispose);
      (container.read(profileProvider.notifier) as _Profile).replaceProfile(
        UserProfile(name: 'Alexandra Catherine Vasala'),
      );
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: HomeGreeting(clock: () => now),
              ),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                const Scaffold(body: Text('Profile destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Good morning, Alexandra Catherine Vasala'),
          findsOneWidget,
        );
        expect(find.text('AV'), findsOneWidget);
        final action = find.byKey(const ValueKey('home-profile-action'));
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        final node = tester.getSemantics(action);
        expect(node.label, contains('Open profile'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(
          node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        (container.read(profileProvider.notifier) as _Profile).replaceProfile(
          UserProfile(name: 'Priya Sharma'),
        );
        await tester.pump();
        expect(find.text('PS'), findsOneWidget);
        expect(find.text('AV'), findsNothing);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.text('Profile destination'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'today preserves the full name at narrow widths and larger text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const name = 'Alexandra Catherine Vasala';
      final now = DateTime(2026, 9, 19, 10);

      await tester.pumpWidget(
        _app(
          HomeGreetingContent(
            name: name,
            selectedDate: now,
            now: now,
            onReturnToToday: () {},
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Good morning, $name'), findsOneWidget);
      expect(find.text('Saturday, 19 September'), findsOneWidget);
      expect(find.text('Return to today'), findsNothing);
      final date = tester.widget<Text>(find.text('Saturday, 19 September'));
      expect(date.style?.fontSize, 13);
    },
  );

  testWidgets(
    'past and future dates give clear context and include another year',
    (tester) async {
      final now = DateTime(2026, 9, 19, 10);
      await tester.pumpWidget(
        _app(
          HomeGreetingContent(
            name: 'Alex',
            selectedDate: DateTime(2025, 9, 19),
            now: now,
            onReturnToToday: () {},
          ),
        ),
      );
      expect(find.text('Your day in review'), findsOneWidget);
      expect(find.text('Friday, 19 September 2025'), findsOneWidget);
      expect(find.text('Good morning, Alex'), findsNothing);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.pumpWidget(
        _app(
          HomeGreetingContent(
            name: 'Alex',
            selectedDate: DateTime(2026, 9, 20),
            now: now,
            onReturnToToday: () {},
          ),
        ),
      );
      expect(find.text('Your day ahead'), findsOneWidget);
      expect(find.text('Sunday, 20 September'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'date announces the selected day and its context without becoming a button',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final now = DateTime(2026, 9, 19, 10);
        for (final scenario in [
          (
            date: now,
            visible: 'Saturday, 19 September',
            spoken: 'Selected day: Saturday, 19 September 2026, today',
          ),
          (
            date: DateTime(2025, 9, 19),
            visible: 'Friday, 19 September 2025',
            spoken: 'Selected day: Friday, 19 September 2025, past day',
          ),
          (
            date: DateTime(2026, 9, 20),
            visible: 'Sunday, 20 September',
            spoken: 'Selected day: Sunday, 20 September 2026, future day',
          ),
        ]) {
          await tester.pumpWidget(
            _app(
              HomeGreetingContent(
                name: 'Alex',
                selectedDate: scenario.date,
                now: now,
                onReturnToToday: () {},
              ),
            ),
          );
          expect(find.text(scenario.visible), findsOneWidget);
          final label = find.bySemanticsLabel(scenario.spoken);
          expect(label, findsOneWidget);
          final node = tester.getSemantics(label);
          expect(node.flagsCollection.isButton, isFalse);
          expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('return to today resets both date and calendar week', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 19, 10);
    await tester.pumpWidget(
      _connectedGreeting(() => now, DateTime(2026, 8, 29)),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeGreeting)),
    );

    await tester.tap(find.text('Return to today'));
    await tester.pump();

    expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
    expect(container.read(weekOffsetProvider), 0);
    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('Return to today'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('greeting updates at noon, evening, and midnight boundaries', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 19, 11, 59, 59);
    await tester.pumpWidget(
      _connectedGreeting(() => now, DateTime(2026, 9, 19)),
    );
    expect(find.text('Good morning, Alex'), findsOneWidget);

    now = DateTime(2026, 9, 19, 12);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Good afternoon, Alex'), findsOneWidget);

    now = DateTime(2026, 9, 19, 17);
    await tester.pump(const Duration(hours: 5));
    expect(find.text('Good evening, Alex'), findsOneWidget);

    now = DateTime(2026, 9, 20);
    await tester.pump(const Duration(hours: 7));
    // The greeting observes the new day without changing the date providers.
    expect(find.text('Your day in review'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeGreeting)),
    );
    container.read(selectedDateProvider.notifier).state = now;
    await tester.pump();
    expect(find.text('Good morning, Alex'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returning to the app refreshes the greeting immediately', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 19, 10);
    await tester.pumpWidget(
      _connectedGreeting(() => now, DateTime(2026, 9, 19)),
    );
    expect(find.text('Good morning, Alex'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 9, 19, 18);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Good evening, Alex'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
