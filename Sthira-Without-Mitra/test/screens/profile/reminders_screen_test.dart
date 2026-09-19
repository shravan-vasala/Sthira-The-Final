import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/reminder_config.dart';
import 'package:trufit_bodamma/providers/reminders_provider.dart';
import 'package:trufit_bodamma/screens/profile/reminders_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/settings_row.dart';

const _permissionError =
    'Notification permission is off. Enable it in system settings to receive reminders.';
const _schedulingError =
    'Reminders could not be updated. Check notification access and try again.';

class _Reminders extends RemindersNotifier {
  _Reminders(this.initial, {this.denyPermission = false});
  final ReminderConfig initial;
  final bool denyPermission;
  int retries = 0;
  @override
  ReminderConfig build() => initial;
  @override
  Future<void> updateConfig(ReminderConfig value) async {
    if (denyPermission) {
      ref.read(reminderErrorProvider.notifier).state = _permissionError;
    } else {
      state = value;
    }
  }

  @override
  Future<void> queueSync() async {
    retries++;
    ref.read(reminderErrorProvider.notifier).state = null;
  }
}

Future<ProviderContainer> _pumpReminders(
  WidgetTester tester,
  _Reminders notifier, {
  String? error,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      remindersProvider.overrideWith(() => notifier),
      reminderErrorProvider.overrideWith((ref) => error),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const RemindersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'expanded time and weekday controls fit 320px with 200 percent text',
    (tester) async {
      final notifier = _Reminders(
        ReminderConfig(
          quietHoursEnabled: true,
          habitsEnabled: true,
          workoutsEnabled: true,
          mealsEnabled: true,
          backupEnabled: true,
          bodyFatEnabled: true,
        ),
      );
      final container = await _pumpReminders(tester, notifier);
      expect(tester.takeException(), isNull);
      for (final label in [
        'Start Time',
        'End Time',
        'Lunch Time',
        'Dinner Time',
        'Day of Week',
      ]) {
        await tester.scrollUntilVisible(find.text(label), 240, maxScrolls: 50);
        await tester.pumpAndSettle();
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull, reason: label);
      }
      final weekday = find.byType(DropdownButton<int>);
      await tester.ensureVisible(weekday);
      await tester.tap(weekday);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wednesday').last);
      await tester.pumpAndSettle();
      expect(
        container.read(remindersProvider).backupDayOfWeek,
        DateTime.wednesday,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('denied permission is visible and does not enable the reminder', (
    tester,
  ) async {
    final container = await _pumpReminders(
      tester,
      _Reminders(ReminderConfig(photosEnabled: false), denyPermission: true),
    );
    await tester.scrollUntilVisible(find.text('Habit Reminder'), 180);
    final row = find.ancestor(
      of: find.text('Habit Reminder'),
      matching: find.byType(SettingsRow),
    );
    final toggle = find.descendant(of: row, matching: find.byType(Switch));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(container.read(remindersProvider).habitsEnabled, isFalse);
    await tester.scrollUntilVisible(
      find.text(_permissionError),
      -240,
      maxScrolls: 30,
    );
    expect(find.text(_permissionError), findsOneWidget);
    expect(find.text('Retry scheduling'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scheduling error exposes retry and clears after successful retry',
    (tester) async {
      final notifier = _Reminders(ReminderConfig());
      final container = await _pumpReminders(
        tester,
        notifier,
        error: _schedulingError,
      );
      expect(find.text(_schedulingError), findsOneWidget);
      final retry = find.text('Retry scheduling');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(notifier.retries, 1);
      expect(container.read(reminderErrorProvider), isNull);
      expect(find.text(_schedulingError), findsNothing);
      expect(find.text('Retry scheduling'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
