import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/coach_note.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widgets/coach_notes_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _account = StateProvider<String>((ref) => 'first');

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() =>
      UserProfile(name: 'Alex', coachName: 'Coach with a longer name');
}

class _Coach extends CoachNoteNotifier {
  @override
  CoachNote build() =>
      CoachNote(date: '2026-09-19', note: 'A grounded reflection.', isAi: true);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'General Sans': ['GeneralSans-Regular.ttf', 'GeneralSans-Semibold.ttf'],
      'Cabinet Grotesk': ['CabinetGrotesk-Extrabold.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final font in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$font'));
      }
      await loader.load();
    }
  });

  ProviderContainer container() => ProviderContainer(
    overrides: [
      activeAccountIdProvider.overrideWith((ref) => ref.watch(_account)),
      profileProvider.overrideWith(_Profile.new),
      coachNoteProvider.overrideWith(_Coach.new),
      coachNoteOutdatedProvider.overrideWithValue(false),
      coachNoteFeedbackProvider.overrideWith(
        (ref) => const CoachNoteFeedback(),
      ),
      clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
      coachHistoryProvider.overrideWith((ref) {
        final account = ref.watch(_account);
        return List.generate(
          7,
          (i) => CoachNote(
            date: '2026-09-${19 - i}',
            note:
                '$account reflection $i. A useful observation about the records for this day.',
            isAi: i.isEven,
          ),
        );
      }),
    ],
  );

  Widget app(ProviderContainer scope, {bool dark = false, double scale = 1}) =>
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: CoachNotesCard(),
            ),
          ),
        ),
      );

  for (final dark in [false, true]) {
    testWidgets('history scrolls and closes at 320/200 dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scope = container();
      addTearDown(scope.dispose);
      await tester.pumpWidget(app(scope, dark: dark, scale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Refresh coach note'), findsOneWidget);
      await tester.tap(find.text('A grounded reflection.'));
      await tester.pumpAndSettle();
      expect(find.text('Coach History'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final last = find.textContaining('first reflection 6');
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close coach history'));
      await tester.pumpAndSettle();
      expect(find.text('Coach History'), findsNothing);
    });
  }

  testWidgets(
    'an open history sheet removes prior account records immediately',
    (tester) async {
      final scope = container();
      addTearDown(scope.dispose);
      await tester.pumpWidget(app(scope));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A grounded reflection.'));
      await tester.pumpAndSettle();
      expect(find.textContaining('first reflection 0'), findsOneWidget);
      scope.read(_account.notifier).state = 'second';
      await tester.pumpAndSettle();
      expect(find.textContaining('first reflection'), findsNothing);
      expect(find.textContaining('Your account changed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
