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
import 'package:trufit_bodamma/utils/target_calculator.dart';
import 'package:trufit_bodamma/widgets/target_estimate_sheet.dart';

class _Profile extends ProfileNotifier {
  _Profile([this.initial]);
  final UserProfile? initial;
  final writes = <UserProfile>[];

  @override
  UserProfile build() =>
      initial ??
      UserProfile(
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
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<TargetEstimateSheet> _openEstimate(WidgetTester tester) async {
  tester.testTextInput.hide();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Suggest for me'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Suggest for me'));
  await tester.pumpAndSettle();
  return tester.widget<TargetEstimateSheet>(find.byType(TargetEstimateSheet));
}

Future<void> _returnEstimate(WidgetTester tester, TargetEstimate? value) async {
  Navigator.of(tester.element(find.byType(TargetEstimateSheet))).pop(value);
  await tester.pumpAndSettle();
}

const _revisedInputs = TargetEstimateInputs(
  heightCm: 163.5,
  weightKg: 71.2,
  age: 31,
  gender: 'F',
  activityLevel: 'Lightly active',
  goal: 'Lose weight',
);

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

  testWidgets(
    'profile estimator uses personal measurements and cancellation preserves targets',
    (tester) async {
      final profile = _Profile(
        UserProfile(
          height: 168,
          currentWeight: 74,
          targetWeight: 61,
          age: 36,
          gender: 'M',
          activityLevel: 'moderate',
          primaryGoal: 'Build muscle',
          targetCalories: 2100,
          useKg: false,
        ),
      );
      await _openEditor(tester, profile);
      await _enter(tester, 2, '169.5');
      final sheet = await _openEstimate(tester);
      expect(sheet.initialInputs.heightCm, 169.5);
      expect(sheet.initialInputs.weightKg, 74);
      expect(sheet.initialInputs.age, 36);
      expect(sheet.initialInputs.gender, 'M');
      expect(
        sheet.initialInputs.activityLevel,
        TargetCalculator.normalizeActivityLevel('moderate'),
      );
      expect(
        sheet.initialInputs.goal,
        TargetCalculator.normalizeGoal('Build muscle'),
      );
      expect(sheet.useKg, isFalse);
      await _returnEstimate(tester, null);
      expect(tester.widget<TextField>(_field(4)).controller!.text, '2100');
      expect(profile.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('accepted estimate remains a local draft until profile Save', (
    tester,
  ) async {
    final profile = _Profile();
    await _openEditor(tester, profile);
    final sheet = await _openEstimate(tester);
    expect(sheet.initialInputs.weightKg, 66); // Not targetWeight 75.
    final estimate = TargetCalculator.estimate(_revisedInputs);
    await _returnEstimate(tester, estimate);
    expect(profile.writes, isEmpty);
    expect(
      tester.widget<TextField>(_field(4)).controller!.text,
      estimate.targets.calories.toString(),
    );
    final reopened = await _openEstimate(tester);
    expect(reopened.initialInputs.weightKg, 71.2);
    expect(reopened.initialInputs.age, 31);
    await _returnEstimate(tester, null);
    await _save(tester);
    expect(profile.writes, hasLength(1));
    final saved = profile.writes.single;
    expect(saved.height, 163.5);
    expect(saved.currentWeight, 71.2);
    expect(saved.targetWeight, 75);
    expect(saved.age, 31);
    expect(saved.gender, 'F');
    expect(saved.activityLevel, _revisedInputs.activityLevel);
    expect(saved.primaryGoal, estimate.inputs.goal);
    expect(saved.targetCalories, estimate.targets.calories);
    expect(saved.targetProteinG, estimate.targets.proteinG);
    expect(saved.targetCarbsG, estimate.targets.carbsG);
    expect(saved.targetFatG, estimate.targets.fatG);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('closing Edit Profile after an estimate discards the draft', (
    tester,
  ) async {
    final profile = _Profile();
    await _openEditor(tester, profile);
    await _openEstimate(tester);
    await _returnEstimate(tester, TargetCalculator.estimate(_revisedInputs));
    Navigator.of(tester.element(_field(0))).pop();
    await tester.pumpAndSettle();
    expect(profile.writes, isEmpty);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('account change retires the editor while estimate is open', (
    tester,
  ) async {
    final profile = _Profile();
    final container = await _openEditor(tester, profile);
    await _openEstimate(tester);
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pump();
    await _returnEstimate(tester, TargetCalculator.estimate(_revisedInputs));
    expect(profile.writes, isEmpty);
    expect(find.text('Account changed'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
