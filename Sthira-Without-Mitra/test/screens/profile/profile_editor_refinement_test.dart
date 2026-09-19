import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/screens/profile/profile_screen.dart';
import 'package:trufit_bodamma/screens/profile/widgets/journey_stats_strip.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  final writes = <UserProfile>[];

  @override
  UserProfile build() => UserProfile(
    name: 'Shravan Vasala',
    coachName: 'Coach',
    height: 180,
    targetWeight: 75,
    targetCalories: 2200,
    targetProteinG: 150,
    targetCarbsG: 250,
    targetFatG: 70,
  );

  @override
  Future<void> updateProfile(UserProfile profile) async {
    writes.add(profile);
    state = profile;
  }
}

class _Theme extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _Cloud extends CloudSyncController {
  @override
  CloudSyncState build() => CloudSyncState.idle;
}

Future<ProviderContainer> _openEditor(
  WidgetTester tester,
  _Profile profile, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(() => profile),
      journeyStatsProvider.overrideWithValue(const JourneyStats()),
      badgesProvider.overrideWithValue([]),
      themeModeProvider.overrideWith(_Theme.new),
      cloudSyncControllerProvider.overrideWith(_Cloud.new),
      isSignedInProvider.overrideWithValue(true),
      userEmailProvider.overrideWithValue('shravan.longemail@example.com'),
      syncPendingCountProvider.overrideWith((ref) => Stream.value(3)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.ensureVisible(find.text('Edit Profile'));
  await tester.tap(find.text('Edit Profile'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return container;
}

Finder _field(int index) => find.byType(TextField).at(index);

Future<void> _enter(WidgetTester tester, int index, String value) async {
  final field = _field(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> _save(WidgetTester tester) async {
  tester.testTextInput.hide();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.ensureVisible(find.text('Save'));
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Sthira',
      packageName: 'com.sthira',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    for (final entry in <String, List<String>>{
      'General Sans': [
        'GeneralSans-Regular.ttf',
        'GeneralSans-Medium.ttf',
        'GeneralSans-Semibold.ttf',
        'GeneralSans-Bold.ttf',
      ],
      'Cabinet Grotesk': [
        'CabinetGrotesk-Regular.ttf',
        'CabinetGrotesk-Medium.ttf',
        'CabinetGrotesk-Bold.ttf',
        'CabinetGrotesk-Extrabold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });

  testWidgets(
    'invalid and nonfinite measurements preserve the editable draft',
    (tester) async {
      final profile = _Profile();
      await _openEditor(tester, profile);
      await _enter(tester, 0, 'My unsaved name');
      await _enter(tester, 2, 'NaN');
      await _enter(tester, 3, 'Infinity');
      await _enter(tester, 4, 'invalid');
      await _save(tester);

      expect(profile.writes, isEmpty);
      expect(
        tester.widget<TextField>(_field(0)).controller!.text,
        'My unsaved name',
      );
      expect(tester.widget<TextField>(_field(2)).controller!.text, 'NaN');
      expect(tester.widget<TextField>(_field(3)).controller!.text, 'Infinity');
      expect(find.text('Enter a height between 1 and 300 cm.'), findsOneWidget);
      expect(
        find.text('Enter a positive target weight below 500.'),
        findsOneWidget,
      );
      expect(
        find.text('Enter a calorie target from 1 to 15000.'),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('macro targets stay editable at 320px and 200 percent text', (
    tester,
  ) async {
    final profile = _Profile();
    await _openEditor(tester, profile, width: 320, textScale: 2);
    for (final entry in {5: '0', 6: '245', 7: '62'}.entries) {
      await _enter(tester, entry.key, entry.value);
      expect(tester.getSize(_field(entry.key)).width, greaterThan(230));
    }
    await _save(tester);
    expect(profile.writes, hasLength(1));
    expect(profile.writes.single.targetProteinG, 0);
    expect(profile.writes.single.targetCarbsG, 245);
    expect(profile.writes.single.targetFatG, 62);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'account transition blocks save and account change retires draft',
    (tester) async {
      final profile = _Profile();
      final container = await _openEditor(tester, profile);
      await _enter(tester, 0, 'Old account draft');
      container.read(accountTransitionProvider.notifier).state = true;
      await _save(tester);
      expect(profile.writes, isEmpty);
      expect(
        tester.widget<TextField>(_field(0)).controller!.text,
        'Old account draft',
      );

      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Account changed'), findsOneWidget);
      expect(
        find.text('Reopen Edit profile for this account.'),
        findsOneWidget,
      );
      expect(find.text('Save'), findsNothing);
      expect(profile.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
