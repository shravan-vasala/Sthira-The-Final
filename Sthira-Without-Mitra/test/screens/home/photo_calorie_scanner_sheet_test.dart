import 'dart:async';
import 'dart:io';
// Platform test double for the already-declared image_picker plugin.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart'
    show ConnectivityPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/interfaces/i_ai_food_service.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/credential_provider.dart';
import 'package:trufit_bodamma/widgets/setup_sheets.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widgets/photo_calorie_scanner_sheet.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/ai_profiler.dart';
import 'package:trufit_bodamma/services/auth_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Connection extends ConnectivityPlatform {
  List<ConnectivityResult> current = [ConnectivityResult.wifi];
  final changes = StreamController<List<ConnectivityResult>>.broadcast();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

class _Picker extends ImagePickerPlatform {
  final String path;
  _Picker(this.path);
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile(path);
}

class _Auth implements AuthService {
  @override
  String get uid => 'test-user';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lookup extends NutritionLookupService {
  @override
  Future<void> load() async {}
}

class _MealCapture extends DailyMealLogNotifier {
  MealSlotLog? saved;

  @override
  DailyMealLog build() => DailyMealLog(date: '2026-09-19');

  @override
  Future<void> saveMealSlot(
    String slotName,
    MealSlotLog slotLog, {
    String? targetDate,
  }) async {
    saved = slotLog;
  }
}

class _ScanProfile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Test');
  @override
  Future<void> updateProfile(UserProfile profile) async {
    state = profile;
  }
}

class _ScanCredentials extends CredentialNotifier {
  @override
  CredentialState build() => const CredentialState(
    status: CredentialStatus.present,
    key: 'fixture-key',
  );
  @override
  Future<void> saveKey(String key) async {
    state = CredentialState(status: CredentialStatus.present, key: key);
  }
}

class _FoodService implements IAiFoodService {
  final pending = <Completer<Map<String, dynamic>?>>[];
  final tokens = <CancellationToken>[];
  final photoStarted = Completer<void>();
  @override
  Future<void> verifyApiKey(String key) async {}
  String? hint;
  List<Uint8List>? photos;
  @override
  Future<Map<String, dynamic>?> analyzeFoodImage(
    List<Uint8List> imageBytesList,
    String mimeType, [
    String? userContext,
    bool skipCache = false,
    bool isAlreadyProcessed = false,
    CancellationToken? cancellationToken,
    AiProfileSession? profiler,
    void Function(AiScanStage)? onProgress,
  ]) {
    hint = userContext;
    photos = imageBytesList;
    final result = analyzeFoodText('', cancellationToken, profiler, onProgress);
    if (!photoStarted.isCompleted) photoStarted.complete();
    return result;
  }

  @override
  Future<Map<String, dynamic>?> analyzeFoodText(
    String description, [
    CancellationToken? cancellationToken,
    AiProfileSession? profiler,
    void Function(AiScanStage)? onProgress,
  ]) {
    final completer = Completer<Map<String, dynamic>?>();
    pending.add(completer);
    tokens.add(cancellationToken!);
    onProgress?.call(AiScanStage.analyzing);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _meal(String name) => {
  'items': [
    <String, dynamic>{
      'name': name,
      'portion': '1 bowl',
      'estimated_grams': 100,
      'calories': 130,
      'protein_g': 3,
      'carbs_g': 28,
      'fat_g': 1,
    },
  ],
  'total': {'calories': 130, 'protein_g': 3, 'carbs_g': 28, 'fat_g': 1},
  'confidence': 'high',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Connection connection;
  late ConnectivityPlatform originalConnection;
  setUp(() {
    originalConnection = ConnectivityPlatform.instance;
    connection = _Connection();
    ConnectivityPlatform.instance = connection;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
  });

  tearDown(() async {
    ConnectivityPlatform.instance = originalConnection;
    await connection.changes.close();
  });

  Future<void> showScanner(
    WidgetTester tester,
    _FoodService service, {
    bool manual = true,
    MealSlotLog? appendToLog,
    _MealCapture? mealCapture,
    Size size = const Size(800, 1200),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_Auth()),
          profileProvider.overrideWith(_ScanProfile.new),
          credentialProvider.overrideWith(_ScanCredentials.new),
          geminiFoodServiceProvider.overrideWithValue(service),
          nutritionLookupServiceProvider.overrideWithValue(_Lookup()),
          if (mealCapture != null)
            dailyMealLogProvider.overrideWith(() => mealCapture),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: PhotoCalorieScannerSheet(
              slotId: 'lunch',
              slotDisplayName: 'Lunch',
              isManualEntry: manual,
              appendToLog: appendToLog,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final failure in [
    AiException(
      'PRIVATE_ERROR',
      cause: AiErrorCause.invalidKey,
      statusCode: 403,
      providerCode: 'PERMISSION_DENIED',
    ),
    AiException(
      'PRIVATE_ERROR',
      cause: AiErrorCause.unknown,
      statusCode: 400,
      providerCode: 'INVALID_ARGUMENT',
    ),
    AiException(
      'PRIVATE_ERROR',
      cause: AiErrorCause.rateLimited,
      statusCode: 429,
      quotaExhausted: true,
    ),
  ]) {
    testWidgets('scanner exposes safe recovery for ${failure.statusCode}', (
      tester,
    ) async {
      final service = _FoodService();
      await showScanner(
        tester,
        service,
        size: const Size(320, 1000),
        textScale: 1.5,
      );
      await tester.enterText(find.byType(TextField), '1 bowl rice');
      await tester.ensureVisible(find.text('Estimate macros'));
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      service.pending.single.completeError(failure);
      await tester.pumpAndSettle();
      expect(find.text(failure.userMessage), findsOneWidget);
      expect(find.textContaining('PRIVATE_ERROR'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Describe instead'), findsNothing);
      expect(
        find.text('AI Settings'),
        failure.cause == AiErrorCause.invalidKey
            ? findsOneWidget
            : findsNothing,
      );
      await tester.ensureVisible(find.text('Details'));
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text(failure.diagnosticSummary!), findsOneWidget);
      await tester.ensureVisible(find.text('Enter yourself'));
      await tester.tap(find.text('Enter yourself'));
      await tester.pumpAndSettle();
      expect(find.text('Add Item'), findsOneWidget);
      expect(service.pending, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'scanner honors provider cooldown before retrying retained description',
    (tester) async {
      final service = _FoodService();
      await showScanner(tester, service);
      await tester.enterText(find.byType(TextField), '1 bowl rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      service.pending.single.completeError(
        AiException(
          'busy',
          cause: AiErrorCause.rateLimited,
          statusCode: 429,
          retryAfter: const Duration(seconds: 3),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Try again in 3 s'), findsOneWidget);
      final button = find.widgetWithText(ElevatedButton, 'Try again in 3 s');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(find.text('Enter yourself'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(service.pending, hasLength(2));
      service.pending.last.complete(_meal('Rice after cooldown'));
      await tester.pumpAndSettle();
      expect(find.text('Rice after cooldown'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final save in [false, true]) {
    testWidgets(
      'AI settings result retries retained description only when saved: $save',
      (tester) async {
        final service = _FoodService();
        await showScanner(tester, service);
        await tester.enterText(find.byType(TextField), '1 bowl rice');
        await tester.tap(find.text('Estimate macros'));
        await tester.pump();
        service.pending.single.completeError(
          AiException(
            'denied',
            cause: AiErrorCause.invalidKey,
            statusCode: 403,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('AI Settings'));
        await tester.pumpAndSettle();
        if (save) {
          await tester.ensureVisible(find.text('Save Changes'));
          await tester.tap(find.text('Save Changes'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          await tester.pump();
          expect(service.pending, hasLength(2));
          service.pending.last.complete(_meal('Recovered rice'));
          await tester.pumpAndSettle();
          expect(find.text('Recovered rice'), findsOneWidget);
        } else {
          Navigator.of(tester.element(find.byType(AiSetupSheet))).pop();
          await tester.pumpAndSettle();
          expect(service.pending, hasLength(1));
          expect(find.text('AI Settings'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('account transition blocks retry before sending retained input', (
    tester,
  ) async {
    final service = _FoodService();
    await showScanner(tester, service);
    await tester.enterText(find.byType(TextField), '1 bowl rice');
    await tester.tap(find.text('Estimate macros'));
    await tester.pump();
    service.pending.single.completeError(
      AiException('timeout', cause: AiErrorCause.timeout),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PhotoCalorieScannerSheet)),
    );
    container.read(accountTransitionProvider.notifier).state = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(service.pending, hasLength(1));
    expect(
      find.text('Date or account changed. Reopen this meal to log it.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final knownCalories in [false, true]) {
    testWidgets(
      'appending food preserves photo-only ${knownCalories ? 'known zero calories' : 'unknown calories'}',
      (tester) async {
        final service = _FoodService();
        final capture = _MealCapture();
        final previous = MealSlotLog.fromJson({
          'photoPath': 'legacy-meal.jpg',
          if (knownCalories) 'caloriesComplete': true,
        });
        await showScanner(
          tester,
          service,
          appendToLog: previous,
          mealCapture: capture,
        );
        await tester.enterText(find.byType(TextField), '1 bowl rice');
        await tester.tap(find.text('Estimate macros'));
        await tester.pump();
        service.pending.single.complete(_meal('Added rice'));
        await tester.pumpAndSettle();
        expect(find.text('Previously photographed meal'), findsOneWidget);
        const saveLabel = 'Save partial log';
        await tester.ensureVisible(find.text(saveLabel));
        await tester.tap(find.text(saveLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final saved = capture.saved!;
        expect(saved.totalCalories, 130);
        expect(saved.hasCompleteCalories, knownCalories);
        expect(saved.hasCompleteMacros, isFalse);
        expect(saved.photoPath, 'legacy-meal.jpg');
        expect(saved.items.first.resolved, knownCalories);
        expect(
          saved.items.first.computedNutrition?.kcal,
          knownCalories ? 0 : null,
        );
        expect(previous.items, isEmpty);
        expect(previous.caloriesComplete, knownCalories ? true : null);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('legacy planned macros stay unknown until explicitly entered', (
    tester,
  ) async {
    final capture = _MealCapture();
    final previous = MealSlotLog(
      confidence: 'planned',
      totalCalories: 400,
      totalProtein: 40,
      totalCarbs: 45,
      totalFat: 8,
      items: [
        MealItemLog(
          name: 'Previous planned food',
          portion: '1 bowl',
          provenance: 'expert_plan',
          computedNutrition: FoodNutrition(
            kcal: 400,
            proteinG: 40,
            carbsG: 45,
            fatG: 8,
          ),
        ),
      ],
    );
    await showScanner(
      tester,
      _FoodService(),
      manual: false,
      appendToLog: previous,
      mealCapture: capture,
    );
    await tester.tap(find.text('Enter macros yourself'));
    await tester.pumpAndSettle();
    expect(find.text('1 bowl \u2022 400 kcal'), findsOneWidget);
    expect(
      find.text('Macros unknown - enter actual values to complete.'),
      findsOneWidget,
    );
    expect(find.text('40.0g'), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
      '400',
    );
    for (var index = 3; index < 6; index++) {
      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(index))
            .controller!
            .text,
        isEmpty,
      );
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter 0 only when known.'), findsOneWidget);
    expect(capture.saved, isNull);
    for (var index = 3; index < 6; index++) {
      await tester.enterText(find.byType(TextField).at(index), '0');
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Log'));
    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(capture.saved!.totalCalories, 400);
    expect(capture.saved!.hasCompleteMacros, isTrue);
    expect(capture.saved!.items.single.macrosKnown, isTrue);
    expect(capture.saved!.totalProtein, 0);
    expect(previous.totalProtein, 40);
    expect(previous.items.single.macrosKnown, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'describe append preserves legacy aggregate without assigning food nutrients',
    (tester) async {
      final service = _FoodService();
      final capture = _MealCapture();
      final previous = MealSlotLog(
        confidence: 'medium',
        totalCalories: 400,
        totalProtein: 20,
        totalCarbs: 60,
        totalFat: 10,
        items: [
          MealItemLog(
            name: 'Legacy detail',
            resolved: false,
            provenance: 'legacy_original',
          ),
        ],
      );
      await showScanner(
        tester,
        service,
        appendToLog: previous,
        mealCapture: capture,
      );
      await tester.enterText(find.byType(TextField), '1 bowl rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      service.pending.single.complete(_meal('Added rice'));
      await tester.pumpAndSettle();
      expect(find.text('Previously saved totals'), findsOneWidget);
      await tester.ensureVisible(find.text('Save partial log'));
      await tester.tap(find.text('Save partial log'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final saved = capture.saved!;
      expect(saved.totalCalories, 530);
      expect(saved.totalProtein, 23);
      expect(saved.totalCarbs, 88);
      expect(saved.totalFat, 11);
      expect(saved.hasCompleteCalories, isFalse);
      expect(saved.hasCompleteMacros, isFalse);
      final detail = saved.items.first;
      expect(detail.name, 'Legacy detail');
      expect(detail.provenance, 'legacy_original');
      expect(detail.computedNutrition, isNull);
      expect(detail.resolved, isFalse);
      expect(detail.macrosKnown, isFalse);
      expect(previous.items, hasLength(1));
      expect(previous.totalCalories, 400);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final (isLiquid, changePortion) in [
    (true, false),
    (false, false),
    (true, true),
  ]) {
    testWidgets(
      'editing packaged ${isLiquid ? 'ml' : 'servings'} with changed portion $changePortion preserves identity',
      (tester) async {
        final mealCapture = _MealCapture();
        final item = MealItemLog(
          name: 'Packaged food',
          portion: isLiquid ? '200 ml' : '2 servings',
          barcode: '8901234567890',
          brand: 'Test brand',
          nutritionBasis: isLiquid ? 'per100ml' : 'perServing',
          consumedMl: isLiquid ? 200 : null,
          consumedServings: isLiquid ? null : 2,
          baseNutrition: FoodNutrition(kcal: 60, proteinG: 3),
          computedNutrition: FoodNutrition(kcal: 120, proteinG: 6),
        );
        await showScanner(
          tester,
          _FoodService(),
          manual: false,
          appendToLog: MealSlotLog(items: [item], totalCalories: 120),
          mealCapture: mealCapture,
        );
        await tester.tap(find.text('Enter macros yourself'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit_rounded));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Renamed food');
        if (changePortion) {
          await tester.enterText(find.byType(TextField).at(1), 'A small glass');
        }
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('\u00bd'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            changePortion
                ? '0.5 \u00d7 A small glass \u2022 60 kcal'
                : isLiquid
                ? '100 ml \u2022 60 kcal'
                : '1 serving \u2022 60 kcal',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Save Log'));
        await tester.tap(find.text('Save Log'));
        await tester.pumpAndSettle();

        final saved = mealCapture.saved!.items.single;
        expect(saved.name, 'Renamed food');
        expect(saved.barcode, item.barcode);
        expect(saved.brand, item.brand);
        expect(saved.nutritionBasis, item.nutritionBasis);
        expect(saved.isPer100g, isFalse);
        expect(saved.consumedGrams, isNull);
        expect(saved.consumedMl, isLiquid && !changePortion ? 100 : null);
        expect(saved.consumedServings, !isLiquid && !changePortion ? 1 : null);
        expect(saved.computedNutrition!.kcal, 60);
        expect(saved.baseNutrition!.kcal, 60);
        expect(item.name, 'Packaged food');
        expect(item.computedNutrition!.kcal, 120);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('photo scan shows progress and cancel keeps the photo and hint', (
    tester,
  ) async {
    final photo = File(
      'test/fixtures/meal_scan/images/idli_chutney_1789715769511.jpg',
    ).absolute;
    final originalPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _Picker(photo.path);
    addTearDown(() => ImagePickerPlatform.instance = originalPicker);
    final service = _FoodService();
    await showScanner(tester, service, manual: false);
    await tester.runAsync(() async {
      await tester.tap(find.text('Gallery'));
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rice, normal portion');
    await tester.tap(find.text('Analyze Photo'));
    await tester.pump();
    // File IO and compute run on real time; pump between waits so callbacks
    // registered in the widget test's fake-async zone can also make progress.
    for (var i = 0; i < 100 && service.photos == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(service.photos, isNotNull);
    expect(service.photos!.length, 1);
    expect(service.hint, 'rice, normal portion');
    expect(find.text('Identifying food and portions...'), findsOneWidget);
    expect(find.text('Add angle\n(Max 3)'), findsNothing);
    await tester.tap(find.byTooltip('Cancel analysis'));
    await tester.pumpAndSettle();
    expect(service.tokens.single.isCancelled, isTrue);
    expect(find.text('Analyze Photo'), findsOneWidget);
    expect(find.text('rice, normal portion'), findsOneWidget);
    service.pending.single.complete(_meal('Stale photo result'));
    await tester.pumpAndSettle();
    expect(find.text('Stale photo result'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'text scan keeps progress visible; cancel preserves input and ignores stale results',
    (tester) async {
      final service = _FoodService();
      await showScanner(tester, service);
      await tester.enterText(find.byType(TextField), '1 bowl rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      expect(find.text('Identifying food and portions...'), findsOneWidget);
      expect(find.byTooltip('Cancel analysis'), findsOneWidget);

      await tester.pump(const Duration(seconds: 13));
      expect(
        find.text('Still waiting for AI. You can cancel and keep your input.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Cancel analysis'));
      await tester.pumpAndSettle();
      expect(service.tokens.first.isCancelled, isTrue);
      expect(find.text('1 bowl rice'), findsOneWidget);

      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      expect(service.pending.length, 2);
      service.pending.first.complete(_meal('Stale rice'));
      await tester.pump();
      expect(find.text('Stale rice'), findsNothing);
      expect(find.byTooltip('Cancel analysis'), findsOneWidget);
      service.pending.last.complete(_meal('Fresh rice'));
      await tester.pumpAndSettle();
      expect(find.text('Fresh rice'), findsOneWidget);
      expect(find.byTooltip('Cancel analysis'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('switching modes cancels the active request', (tester) async {
    final service = _FoodService();
    await showScanner(tester, service);
    await tester.enterText(find.byType(TextField), '1 bowl rice');
    await tester.tap(find.text('Estimate macros'));
    await tester.pump();
    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();
    expect(service.tokens.single.isCancelled, isTrue);
    service.pending.single.complete(_meal('Late result'));
    await tester.pumpAndSettle();
    expect(find.text('Late result'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reconnecting enables estimation without reopening or losing input',
    (tester) async {
      connection.current = [ConnectivityResult.none];
      final service = _FoodService();
      await showScanner(tester, service);
      await tester.enterText(find.byType(TextField), '150 grams rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      expect(service.pending, isEmpty);
      connection.changes.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      expect(service.pending, hasLength(1));
      expect(find.text('150 grams rice'), findsOneWidget);
      await tester.tap(find.byTooltip('Cancel analysis'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('scaled portions keep their meaning in the saved log', (
    tester,
  ) async {
    final service = _FoodService();
    final capture = _MealCapture();
    await showScanner(tester, service, mealCapture: capture);
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.tap(find.text('Estimate macros'));
    await tester.pump();
    service.pending.single.complete(_meal('Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u00bd'));
    await tester.pumpAndSettle();
    expect(find.text('0.5 \u00d7 1 bowl \u2022 65 kcal'), findsOneWidget);
    await tester.ensureVisible(find.text('Save Log'));
    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
    expect(capture.saved!.items.single.portion, '0.5 \u00d7 1 bowl');
    expect(capture.saved!.items.single.consumedGrams, 50);
    expect(capture.saved!.totalCalories, 65);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'partial review uses actual item coverage and labels incomplete totals',
    (tester) async {
      final service = _FoodService();
      await showScanner(
        tester,
        service,
        appendToLog: MealSlotLog(
          items: [MealItemLog(name: 'Unknown curry', resolved: false)],
        ),
      );
      await tester.enterText(find.byType(TextField), 'rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      service.pending.single.complete(_meal('Rice'));
      await tester.pumpAndSettle();
      expect(find.text('Known total'), findsOneWidget);
      expect(find.text('1 item needs review'), findsOneWidget);
      expect(find.text('Save partial log'), findsOneWidget);
      expect(find.text('130 kcal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'scanner actions and reviewed meals fit 320px at double text size',
    (tester) async {
      final service = _FoodService();
      await showScanner(
        tester,
        service,
        manual: false,
        size: const Size(320, 900),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Or describe in text'));
      await tester.tap(find.text('Or describe in text'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'rice and curry');
      await tester.ensureVisible(find.text('Estimate macros'));
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      service.pending.single.complete(_meal('Rice and vegetable curry'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('1\u00bd'));
      await tester.tap(find.text('1\u00bd'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Log'));
      expect(tester.takeException(), isNull);
      expect(find.text('Save Log').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'invalid corrections stay editable and valid corrections survive scaling',
    (tester) async {
      final service = _FoodService();
      await showScanner(tester, service);
      await tester.enterText(find.byType(TextField), 'rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      final meal = _meal('Rice');
      ((meal['items'] as List).single as Map<String, dynamic>).addAll({
        'baseNutrition': FoodNutrition(
          kcal: 130,
          proteinG: 3,
          carbsG: 28,
          fatG: 1,
        ).toJson(),
        'is_per_100g': true,
      });
      service.pending.single.complete(meal);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Rice'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), 'not a number');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('valid non-negative nutrition'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).at(2), '200');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('\u00bd'));
      await tester.pumpAndSettle();
      expect(find.text('0.5 \u00d7 1 bowl \u2022 100 kcal'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'adding to aggregate-only legacy meals preserves earlier nutrition',
    (tester) async {
      final service = _FoodService();
      final capture = _MealCapture();
      await showScanner(
        tester,
        service,
        mealCapture: capture,
        appendToLog: MealSlotLog(
          items: [],
          totalCalories: 350,
          totalProtein: 12,
          totalCarbs: 50,
          totalFat: 10,
        ),
      );
      await tester.enterText(find.byType(TextField), 'rice');
      await tester.tap(find.text('Estimate macros'));
      await tester.pump();
      service.pending.single.complete(_meal('Rice'));
      await tester.pumpAndSettle();
      expect(find.text('Previously logged food'), findsOneWidget);
      expect(find.text('480 kcal'), findsOneWidget);
      await tester.ensureVisible(find.text('Save Log'));
      await tester.tap(find.text('Save Log'));
      await tester.pumpAndSettle();
      expect(capture.saved!.totalCalories, 480);
      expect(capture.saved!.totalProtein, 15);
      expect(capture.saved!.items, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('removal undo is safe after closing the scanner', (tester) async {
    final service = _FoodService();
    await showScanner(tester, service);
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.tap(find.text('Estimate macros'));
    await tester.pump();
    service.pending.single.complete(_meal('Rice'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
    await tester.pumpAndSettle();
    final undo = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(undo.onPressed, returnsNormally);
    expect(tester.takeException(), isNull);
  });
}
