import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/credential_provider.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/about_you_page.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/connect_page.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/welcome_page.dart';
import 'package:trufit_bodamma/screens/onboarding/pages/your_plan_page.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

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

Widget _app(Widget page) => ProviderScope(
  overrides: [
    credentialProvider.overrideWith(_Credentials.new),
    cloudSyncControllerProvider.overrideWith(_Cloud.new),
    isSignedInProvider.overrideWithValue(false),
    healthConnectServiceProvider.overrideWithValue(_Health()),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: Scaffold(body: page),
  ),
);

void main() {
  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'welcome wraps the tagline and gives accurate offline expectations',
    (tester) async {
      narrow(tester);
      await tester.pumpWidget(_app(const WelcomePage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Your saved plans and logs work offline.'),
        findsOneWidget,
      );
      expect(find.textContaining('Internet required'), findsOneWidget);
    },
  );

  testWidgets('about-you fields remain usable at 320px and 200% text', (
    tester,
  ) async {
    narrow(tester);
    final controllers = List.generate(4, (_) => TextEditingController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
    await tester.pumpWidget(
      _app(
        AboutYouPage(
          nameController: controllers[0],
          coachController: controllers[1],
          heightController: controllers[2],
          weightController: controllers[3],
          useKg: true,
          onToggleUnit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Weight (Optional)'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'expert starting target stays until a preview is explicitly applied',
    (tester) async {
      narrow(tester);
      double? changed;
      await tester.pumpWidget(
        _app(
          YourPlanPage(
            initialCalories: 1250,
            heightCm: 170,
            weightKg: 70,
            selectedHabitIds: const ['sleep', 'walk', 'water'],
            isManuallyEdited: false,
            onCaloriesChanged: (value, manual) => changed = value,
            onHabitToggled: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(changed, isNull);
      expect(find.text('1250 kcal'), findsOneWidget);
      expect(find.text('Expert-suggested starting target'), findsOneWidget);
      await tester.ensureVisible(find.text('Suggest for me'));
      await tester.tap(find.text('Suggest for me'));
      await tester.pumpAndSettle();
      expect(changed, isNull);
      await tester.ensureVisible(find.byTooltip('Close'));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(changed, isNull);
      expect(find.text('1250 kcal'), findsOneWidget);
      await tester.ensureVisible(find.text('Suggest for me'));
      await tester.tap(find.text('Suggest for me'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Use these targets'));
      await tester.tap(find.text('Use these targets'));
      await tester.pumpAndSettle();
      expect(changed, isNotNull);
      expect(find.text('Suggested estimate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('connect controls wrap and missing API key stays optional', (
    tester,
  ) async {
    narrow(tester);
    await tester.pumpWidget(_app(const ConnectPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Missing Key'), findsNothing);
    expect(find.text('Optional'), findsNWidgets(2));
    for (final button in tester.widgetList<TextButton>(
      find.byType(TextButton),
    )) {
      expect(button.onPressed, isNotNull);
    }
  });
}
