import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/haptics.dart';
import 'package:trufit_bodamma/models/badge.dart';
import 'package:trufit_bodamma/providers/account_scope_provider.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/theme/app_motion.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/badge_overlay_host.dart';

Badge _badge(String title, {String id = 'meal_days_7'}) => Badge(
  id: id,
  category: 'meal',
  title: title,
  description: 'Record a meal on 7 different days.',
  iconEmoji: 'M',
  requiredProgress: 7,
  currentProgress: 7,
  unlockedAt: DateTime(2026, 9, 19),
);

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  bool reduceMotion = false,
  bool accessible = false,
  double textScale = 1,
  bool prequeued = false,
  bool light = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      badgesProvider.overrideWithValue([_badge('Catalog meal trophy')]),
    ],
  );
  addTearDown(container.dispose);
  if (prequeued) {
    container
        .read(badgeUnlockEventProvider.notifier)
        .enqueue(_badge('Waiting trophy'));
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: light ? AppTheme.light : AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            accessibleNavigation: accessible,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: Stack(children: [SizedBox.expand(), BadgeOverlayHost()]),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void _beginDismiss(WidgetTester tester, String title) {
  final detector = tester.widget<GestureDetector>(
    find
        .ancestor(of: find.text(title), matching: find.byType(GestureDetector))
        .first,
  );
  detector.onVerticalDragUpdate!(
    DragUpdateDetails(delta: const Offset(0, -3), globalPosition: Offset.zero),
  );
  final banner = tester.widget<AnimatedBuilder>(
    find
        .descendant(
          of: find.byType(BadgeOverlayHost),
          matching: find.byType(AnimatedBuilder),
        )
        .first,
  );
  expect(
    (banner.animation as Animation<double>).status,
    AnimationStatus.reverse,
  );
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'account reset hides banner and old timer cannot dismiss same badge on new account',
    (tester) async {
      final container = await _mount(tester);
      final queue = container.read(badgeUnlockEventProvider.notifier);
      queue.enqueue(_badge('Old account meal trophy'));
      await tester.pump();
      await tester.pump(Motion.deliberate);
      expect(find.text('Old account meal trophy'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      expect(find.text('Old account meal trophy'), findsNothing);
      expect(container.read(badgeUnlockEventProvider), isEmpty);

      container
          .read(badgeUnlockEventProvider.notifier)
          .enqueue(_badge('New account meal trophy'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('New account meal trophy'), findsOneWidget);
      expect(
        container.read(badgeUnlockEventProvider).single.title,
        'New account meal trophy',
      );
      await _finish(tester);
    },
  );

  testWidgets(
    'account reset cancels a pending reverse animation before it can dequeue new badge',
    (tester) async {
      final container = await _mount(tester);
      container
          .read(badgeUnlockEventProvider.notifier)
          .enqueue(_badge('Old account meal trophy'));
      await tester.pump();
      await tester.pump(Motion.deliberate);

      _beginDismiss(tester, 'Old account meal trophy');
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      container
          .read(badgeUnlockEventProvider.notifier)
          .enqueue(_badge('New account meal trophy'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Old account meal trophy'), findsNothing);
      expect(find.text('New account meal trophy'), findsOneWidget);
      expect(container.read(badgeUnlockEventProvider), hasLength(1));
      await _finish(tester);
    },
  );

  testWidgets('empty queue cancels the active banner and its old timeout', (
    tester,
  ) async {
    final container = await _mount(tester);
    final queue = container.read(badgeUnlockEventProvider.notifier);
    queue.enqueue(_badge('Removed trophy'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    queue.dequeue();
    await tester.pump();
    expect(find.text('Removed trophy'), findsNothing);

    queue.enqueue(_badge('Retained trophy', id: 'meal_days_30'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Retained trophy'), findsOneWidget);
    expect(container.read(badgeUnlockEventProvider).single.id, 'meal_days_30');
    await _finish(tester);
  });

  testWidgets('empty queue and disposal cancel a scheduled next-banner gap', (
    tester,
  ) async {
    final container = await _mount(tester);
    final queue = container.read(badgeUnlockEventProvider.notifier);
    queue.enqueue(_badge('First trophy'));
    queue.enqueue(_badge('Second trophy', id: 'meal_days_30'));
    await tester.pump();
    await tester.pump(Motion.deliberate);
    _beginDismiss(tester, 'First trophy');
    await tester.pump();
    await tester.pump(Motion.standard + const Duration(milliseconds: 1));
    await tester.pump();
    expect(container.read(badgeUnlockEventProvider), hasLength(1));
    expect(
      container.read(badgeUnlockEventProvider).single.title,
      'Second trophy',
    );
    expect(find.text('First trophy'), findsNothing);
    expect(find.text('Second trophy'), findsNothing);
    queue.dequeue();
    await tester.pump();
    expect(find.text('Second trophy'), findsNothing);
    await _finish(tester);
    expect(container.read(badgeUnlockEventProvider), isEmpty);
  });

  testWidgets(
    'repeated dismissal gestures consume one badge and reduced motion still advances queue',
    (tester) async {
      final container = await _mount(tester, reduceMotion: true);
      final queue = container.read(badgeUnlockEventProvider.notifier);
      queue.enqueue(_badge('First trophy'));
      queue.enqueue(_badge('Second trophy', id: 'meal_days_30'));
      await tester.pumpAndSettle();
      final detector = tester.widget<GestureDetector>(
        find
            .ancestor(
              of: find.text('First trophy'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      final update = DragUpdateDetails(
        delta: const Offset(0, -3),
        globalPosition: Offset.zero,
      );
      detector.onVerticalDragUpdate!(update);
      detector.onVerticalDragUpdate!(update);
      await tester.pumpAndSettle();
      expect(container.read(badgeUnlockEventProvider), hasLength(1));
      expect(
        container.read(badgeUnlockEventProvider).single.id,
        'meal_days_30',
      );
      expect(find.text('Second trophy'), findsOneWidget);
      await _finish(tester);
    },
  );
  testWidgets(
    'prequeued trophy appears after host mounts and has a named dismiss target',
    (tester) async {
      final container = await _mount(
        tester,
        prequeued: true,
        reduceMotion: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting trophy'), findsOneWidget);
      final close = find.byTooltip('Dismiss achievement');
      expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(container.read(badgeUnlockEventProvider), isEmpty);
      await _finish(tester);
    },
  );

  testWidgets(
    'accessible navigation retains the trophy until explicit dismissal',
    (tester) async {
      final container = await _mount(
        tester,
        accessible: true,
        reduceMotion: true,
      );
      container
          .read(badgeUnlockEventProvider.notifier)
          .enqueue(_badge('Readable trophy'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Readable trophy'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss achievement'));
      await tester.pumpAndSettle();
      expect(container.read(badgeUnlockEventProvider), isEmpty);
      await _finish(tester);
    },
  );

  testWidgets('background time does not consume unseen trophies', (
    tester,
  ) async {
    final container = await _mount(tester, reduceMotion: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    container
        .read(badgeUnlockEventProvider.notifier)
        .enqueue(_badge('Resume trophy'));
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Resume trophy'), findsNothing);
    expect(container.read(badgeUnlockEventProvider), hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Resume trophy'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Resume trophy'), findsOneWidget);
    await _finish(tester);
  });

  for (final light in [false, true]) {
    testWidgets(
      'full trophy copy and controls fit 320px at 200 percent text, light=$light',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = await _mount(
          tester,
          reduceMotion: true,
          accessible: true,
          textScale: 2,
          light: light,
        );
        container
            .read(badgeUnlockEventProvider.notifier)
            .enqueue(_badge('Welcome to the Iron'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('View trophies'), findsOneWidget);
        expect(find.text('Record a meal on 7 different days.'), findsOneWidget);
        await tester.tap(find.byTooltip('Dismiss achievement'));
        await tester.pumpAndSettle();
        expect(container.read(badgeUnlockEventProvider), isEmpty);
        await _finish(tester);
      },
    );
  }

  testWidgets('celebration respects the existing haptic preference', (
    tester,
  ) async {
    final original = Haptics.enabled;
    Haptics.enabled = false;
    addTearDown(() => Haptics.enabled = original);
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = await _mount(tester, reduceMotion: true);
    container
        .read(badgeUnlockEventProvider.notifier)
        .enqueue(_badge('Quiet trophy'));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call == 'HapticFeedback.vibrate'), isEmpty);
    await _finish(tester);
  });
}
