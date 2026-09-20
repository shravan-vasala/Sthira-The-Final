import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/credential_provider.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/screens/onboarding/onboarding_screen.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/about_you_page.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/your_plan_page.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/utils/target_calculator.dart';
import 'package:trufit_bodamma/widgets/target_estimate_sheet.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.initial);
  final UserProfile initial;
  final writes = <UserProfile>[];
  @override
  UserProfile build() => initial;
  @override
  Future<void> updateProfile(UserProfile profile) async {
    writes.add(profile);
    state = profile;
  }
}

class _Habits extends HabitRepository {
  @override
  List<Habit> getHabits() => Habit.defaults;
  @override
  Future<void> saveHabit(Habit habit) async {}
  @override
  Future<void> deleteHabit(String id) async {}
}

class _Completion extends OnboardingCompletedNotifier {
  int saves = 0;
  @override
  bool build() => false;
  @override
  Future<void> commitLocalSetup() async {
    saves++;
  }
}

class _Health extends Fake implements HealthConnectService {
  @override
  Future<bool> isAuthorized() async => false;
}

class _Credentials extends CredentialNotifier {
  @override
  CredentialState build() =>
      const CredentialState(status: CredentialStatus.removed);
}

class _Cloud extends CloudSyncController {
  @override
  CloudSyncState build() => CloudSyncState.idle;
}

const revisedInputs = TargetEstimateInputs(
  heightCm: 172,
  weightKg: 78,
  age: 37,
  gender: 'M',
  activityLevel: 'Moderately active',
  goal: 'Lose weight',
);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> _mountOnboarding(
  WidgetTester tester,
  _Profile profile,
  _Completion completion,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => profile),
        habitRepoProvider.overrideWithValue(_Habits()),
        onboardingCompletedProvider.overrideWith(() => completion),
        credentialProvider.overrideWith(_Credentials.new),
        cloudSyncControllerProvider.overrideWith(_Cloud.new),
        isSignedInProvider.overrideWithValue(false),
        healthConnectServiceProvider.overrideWithValue(_Health()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final personal in [false, true]) {
    testWidgets(
      'onboarding keeps accepted inputs as draft until completion, personal=$personal',
      (tester) async {
        final profile = _Profile(
          UserProfile(
            name: personal ? 'Existing user' : '',
            useKg: !personal,
            height: personal ? 168 : null,
            currentWeight: personal ? 72 : null,
            age: personal ? 42 : null,
            gender: personal ? 'M' : null,
            activityLevel: personal ? 'Lightly active' : null,
            primaryGoal: personal ? 'Gain weight' : null,
            targetWeight: 55,
            activeMealPlan: 'Expert plan',
          ),
        );
        final completion = _Completion();
        await _mountOnboarding(tester, profile, completion);
        await tapText(tester, 'Next');
        final about = tester.widget<AboutYouPage>(find.byType(AboutYouPage));
        expect(double.parse(about.heightController.text), personal ? 168 : 153);
        expect(
          double.parse(about.weightController.text),
          personal ? closeTo(72 * 2.20462, 0.06) : 66,
        );
        if (!personal) {
          await tester.enterText(
            find.byWidgetPredicate(
              (w) => w is EditableText && w.controller == about.nameController,
            ),
            'Sister',
          );
        }
        await tapText(tester, 'Next');
        await tapText(tester, 'Suggest for me');
        final sheet = tester.widget<TargetEstimateSheet>(
          find.byType(TargetEstimateSheet),
        );
        expect(sheet.initialInputs.age, personal ? 42 : 29);
        expect(sheet.initialInputs.gender, personal ? 'M' : 'F');
        expect(
          sheet.initialInputs.activityLevel,
          personal ? 'Lightly active' : 'Sedentary',
        );
        final accepted = TargetCalculator.estimate(revisedInputs);
        Navigator.of(
          tester.element(find.byType(TargetEstimateSheet)),
        ).pop(accepted);
        await tester.pumpAndSettle();
        expect(profile.writes, isEmpty);
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
        await tester.pumpAndSettle();
        final updatedAbout = tester.widget<AboutYouPage>(
          find.byType(AboutYouPage),
        );
        expect(double.parse(updatedAbout.heightController.text), 172);
        expect(
          double.parse(updatedAbout.weightController.text),
          closeTo(78 * (personal ? 2.20462 : 1), 0.01),
        );
        await tapText(tester, 'Next');
        await tapText(tester, 'Next');
        await tapText(tester, 'Start my journey');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(profile.writes, hasLength(1));
        final saved = profile.writes.single;
        expect(saved.age, 37);
        expect(saved.gender, 'M');
        expect(saved.activityLevel, 'Moderately active');
        expect(saved.primaryGoal, 'Lose weight');
        expect(saved.height, 172);
        expect(saved.currentWeight, 78);
        expect(saved.targetCalories, accepted.targets.calories);
        expect(saved.targetProteinG, accepted.targets.proteinG);
        expect(saved.targetCarbsG, accepted.targets.carbsG);
        expect(saved.targetFatG, accepted.targets.fatG);
        expect(saved.targetWeight, 55);
        expect(saved.activeMealPlan, 'Expert plan');
        expect(completion.saves, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'onboarding ignores an estimate returned to a different account session',
    (tester) async {
      var session = 0;
      StateSetter? rebuild;
      var applications = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: YourPlanPage(
                  initialCalories: 1250,
                  heightCm: 153,
                  weightKg: 66,
                  estimateSession: session,
                  initialMacros: const TargetMacros(
                    calories: 1250,
                    proteinG: 85,
                    carbsG: 135,
                    fatG: 40,
                  ),
                  selectedHabitIds: const ['walk'],
                  isManuallyEdited: false,
                  onCaloriesChanged: (_, _) => applications++,
                  onHabitToggled: (_, _) {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Suggest for me');
      rebuild!(() => session++);
      await tester.pump();
      Navigator.of(
        tester.element(find.byType(TargetEstimateSheet)),
      ).pop(TargetCalculator.estimate(revisedInputs));
      await tester.pumpAndSettle();
      expect(applications, 0);
      expect(find.text('1250 kcal'), findsOneWidget);
    },
  );
  for (final weight in [30.0, 200.0]) {
    testWidgets('onboarding unit toggle preserves valid boundary $weight kg', (
      tester,
    ) async {
      final profile = _Profile(
        UserProfile(name: 'Boundary', height: 153, currentWeight: weight),
      );
      await _mountOnboarding(tester, profile, _Completion());
      await tapText(tester, 'Next');
      var about = tester.widget<AboutYouPage>(find.byType(AboutYouPage));
      about.onToggleUnit();
      await tester.pumpAndSettle();
      about = tester.widget<AboutYouPage>(find.byType(AboutYouPage));
      expect(
        double.parse(about.weightController.text),
        closeTo(weight * 2.20462, .01),
      );
      about.onToggleUnit();
      await tester.pumpAndSettle();
      expect(double.parse(about.weightController.text), weight);
      about.onToggleUnit();
      await tester.pumpAndSettle();
      await tapText(tester, 'Next');
      expect(find.byType(YourPlanPage), findsOneWidget);
      expect(
        tester.widget<YourPlanPage>(find.byType(YourPlanPage)).weightKg,
        weight,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'same-calorie profile refresh replaces macro chips and slider base',
    (tester) async {
      var macros = const TargetMacros(
        calories: 1250,
        proteinG: 85,
        carbsG: 135,
        fatG: 40,
      );
      StateSetter? rebuild;
      TargetMacros? changed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: YourPlanPage(
                  initialCalories: 1250,
                  initialMacros: macros,
                  heightCm: 153,
                  weightKg: 66,
                  selectedHabitIds: const ['walk'],
                  isManuallyEdited: false,
                  onCaloriesChanged: (_, _) {},
                  onMacrosChanged: (value) => changed = value,
                  onHabitToggled: (_, _) {},
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('P 85g'), findsOneWidget);
      rebuild!(
        () => macros = const TargetMacros(
          calories: 1250,
          proteinG: 110,
          carbsG: 100,
          fatG: 40,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('P 110g'), findsOneWidget);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(1500);
      await tester.pump();
      expect(changed!.proteinG, 110);
    },
  );
}
