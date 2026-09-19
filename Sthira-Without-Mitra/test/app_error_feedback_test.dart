import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/main.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/reminders_provider.dart';

final _accountId = StateProvider<String>((ref) => 'first-account');

class _Session implements AccountSession {
  int retries = 0;

  @override
  Future<void> refresh() async => retries++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late _Session session;
  late GlobalKey<ScaffoldMessengerState> messenger;

  setUp(() {
    session = _Session();
    messenger = GlobalKey<ScaffoldMessengerState>();
    container = ProviderContainer(
      overrides: [
        accountSessionProvider.overrideWithValue(session),
        activeAccountIdProvider.overrideWith((ref) => ref.watch(_accountId)),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        scaffoldMessengerKey: messenger,
        builder: (context, child) => AppErrorFeedback(child: child!),
        home: const Scaffold(body: Text('Current account')),
      ),
    ),
  );

  testWidgets(
    'normal errors preserve Undo and duplicate reports share one bar',
    (tester) async {
      await mount(tester);
      var undone = false;
      messenger.currentState!.showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 1),
          content: const Text('Entry removed'),
          action: SnackBarAction(label: 'Undo', onPressed: () => undone = true),
        ),
      );
      await tester.pumpAndSettle();
      container.read(reminderErrorProvider.notifier).state = 'Try again later';
      container.read(socialErrorProvider.notifier).state = 'Try again later';
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Try again later'), findsNothing);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(find.text('Try again later'), findsOneWidget);
      messenger.currentState!.hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('blocked account screen owns Retry until loading finishes', (
    tester,
  ) async {
    await mount(tester);
    container.read(accountTransitionProvider.notifier).state = true;
    container.read(accountHydratingProvider.notifier).state = true;
    container.read(accountGenerationProvider.notifier).state++;
    container.read(reminderErrorProvider.notifier).state = 'Old reminder';
    container.read(socialErrorProvider.notifier).state = 'Old social request';
    container.read(accountSessionErrorProvider.notifier).state = 'Sync failed';
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    // AccountSession advances the generation immediately after lowering its
    // transition barrier. The current failure must survive that final advance.
    container.read(accountTransitionProvider.notifier).state = false;
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    container.read(accountHydratingProvider.notifier).state = false;
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.text('Old reminder'), findsNothing);
    expect(find.text('Old social request'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(session.retries, 1);
    expect(find.byType(SnackBar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'account change clears visible and queued messages and old Retry',
    (tester) async {
      await mount(tester);
      container.read(accountSessionErrorProvider.notifier).state =
          'First failure';
      await tester.pumpAndSettle();
      final oldRetry = tester
          .widget<SnackBarAction>(find.byType(SnackBarAction))
          .onPressed;
      container.read(reminderErrorProvider.notifier).state = 'First reminder';
      await tester.pumpAndSettle();
      container.read(_accountId.notifier).state = 'second-account';
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      oldRetry();
      expect(session.retries, 0);
      container.read(accountSessionErrorProvider.notifier).state =
          'Second failure';
      await tester.pumpAndSettle();
      expect(find.text('Second failure'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(session.retries, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('late first-account messages are discarded before presentation', (
    tester,
  ) async {
    await mount(tester);
    container.read(reminderErrorProvider.notifier).state = 'Stale reminder';
    container.read(accountSessionErrorProvider.notifier).state =
        'Stale failure';
    container.read(_accountId.notifier).state = 'second-account';
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    container.read(socialErrorProvider.notifier).state =
        'Current request failed';
    await tester.pumpAndSettle();
    expect(find.text('Current request failed'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
