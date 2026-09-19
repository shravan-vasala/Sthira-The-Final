import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/screens/home/steps_entry_dialog.dart';
import 'package:trufit_bodamma/screens/home/widgets/daily_progress_grid.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/surface_card.dart';

final _today = DateTime(2026, 9, 19);
const _todayKey = '2026-09-19';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alex');
}

class _Logs extends DailyLogNotifier {
  _Logs(this.logs);
  final Map<String, DailyLog> logs;
  @override
  DailyLog build() {
    final date = ref.watch(dateStringProvider);
    return logs[date] ?? DailyLog(date: date);
  }
}

class _Repository extends Fake implements DailyLogRepository {
  @override
  List<DailyLog> getLogsInRange(String from, String to) => [];
}

class _Media extends Fake implements MediaRepository {
  _Media(this.count);
  final int count;
  @override
  List<MapEntry<String, List<String>>> getAllProgressPhotos() => [
    MapEntry(_todayKey, List.generate(count, (i) => 'missing-progress-$i.jpg')),
  ];
  @override
  String getAbsolutePath(String path) => path;
}

class _Health extends Fake implements HealthConnectService {
  _Health({this.connected = false, this.pendingCheck});
  final bool connected;
  final Future<bool>? pendingCheck;
  int requests = 0;
  @override
  Future<bool> canReadSteps() => pendingCheck ?? Future.value(connected);
  @override
  Future<bool> isAuthorized() async => connected;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> requestPermission() async {
    requests++;
    return false;
  }
}

Future<ProviderContainer> _show(
  WidgetTester tester, {
  double width = 320,
  double scale = 1,
  bool dark = true,
  int photos = 0,
  DateTime? selected,
  _Health? health,
  Map<String, DailyLog> logs = const {},
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(_today),
      selectedDateProvider.overrideWith((ref) => selected ?? _today),
      profileProvider.overrideWith(_Profile.new),
      dailyLogProvider.overrideWith(() => _Logs(logs)),
      dailyLogRepoProvider.overrideWithValue(_Repository()),
      mediaRepoProvider.overrideWithValue(_Media(photos)),
      healthConnectServiceProvider.overrideWithValue(health ?? _Health()),
      accountGenerationProvider.overrideWith((ref) => 0),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: SingleChildScrollView(child: DailyProgressGrid()),
        ),
      ),
      GoRoute(
        path: '/home/physique-pictures',
        builder: (context, state) =>
            const Scaffold(body: Text('Physique destination')),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => Scaffold(
          body: Text('Progress: ${state.uri.queryParameters['metric']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}

Finder _tile(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SurfaceCard));

void _expectUnwrappedTitle(WidgetTester tester, String title) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
  final naturalText = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout();
  // Compare rendered text with its natural single-line height, rather than a
  // minimum glyph width that changes with the font and text scale.
  expect(paragraph.size.height, closeTo(naturalText.height, 0.01));
  expect(paragraph.didExceedMaxLines, isFalse);
  naturalText.dispose();
}

void main() {
  setUpAll(() async {
    for (final font in {
      'General Sans': 'assets/fonts/GeneralSans-Medium.ttf',
      'Cabinet Grotesk': 'assets/fonts/CabinetGrotesk-Bold.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  for (final dark in [true, false]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('photos and Connect fit at 320px/$scale dark=$dark', (
        tester,
      ) async {
        final health = _Health();
        await _show(
          tester,
          photos: 5,
          scale: scale,
          dark: dark,
          health: health,
        );
        // Complete missing-file reads so the fallback is exercised.
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        expect(find.text('5 progress photos'), findsOneWidget);
        expect(find.text('+3'), findsOneWidget);
        expect(find.byIcon(Icons.photo_outlined), findsNWidgets(2));
        final title = tester.getRect(find.text('Physique'));
        final previews = tester.getRect(find.byType(Image).first);
        expect(previews.top, greaterThan(title.bottom));
        _expectUnwrappedTitle(tester, 'Physique');
        final connect = find.widgetWithText(TextButton, 'Connect');
        await tester.ensureVisible(connect);
        final rect = tester.getRect(connect);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(20));
        expect(rect.right, lessThanOrEqualTo(300));
        expect(tester.takeException(), isNull);
        await tester.tap(connect);
        await tester.pumpAndSettle();
        expect(health.requests, 1);
        expect(find.byType(StepsEntryDialog), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'wider Physique tile keeps a restrained preview and opens gallery',
    (tester) async {
      await _show(tester, width: 390, photos: 5);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('+4'), findsOneWidget);
      expect(find.text('5 progress photos'), findsOneWidget);
      _expectUnwrappedTitle(tester, 'Physique');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Physique'));
      await tester.pumpAndSettle();
      expect(find.text('Physique destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final startToday in [true, false]) {
    testWidgets('Connect follows selected day starting today=$startToday', (
      tester,
    ) async {
      final container = await _show(
        tester,
        selected: startToday ? _today : DateTime(2026, 9, 18),
      );
      expect(
        find.widgetWithText(TextButton, 'Connect'),
        startToday ? findsOneWidget : findsNothing,
      );
      for (final day in [18, 19, 20, 19]) {
        container.read(selectedDateProvider.notifier).state = DateTime(
          2026,
          9,
          day,
        );
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(TextButton, 'Connect'),
          day == 19 ? findsOneWidget : findsNothing,
        );
        if (day == 20) {
          expect(tester.widget<SurfaceCard>(_tile('Steps')).onTap, isNull);
          expect(
            tester.widget<SurfaceCard>(_tile('Body Weight')).onTap,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
      }
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        18,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Steps'));
      await tester.tap(find.text('Steps'));
      await tester.pumpAndSettle();
      expect(find.byType(StepsEntryDialog), findsOneWidget);
      expect(find.text('Enter your step count for 18 Sep'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'permission check finishing after a date switch uses the current day',
    (tester) async {
      final permission = Completer<bool>();
      final container = await _show(
        tester,
        health: _Health(pendingCheck: permission.future),
        settle: false,
      );
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        18,
      );
      await tester.pump();
      permission.complete(false);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Connect'), findsNothing);
      container.read(selectedDateProvider.notifier).state = _today;
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Connect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'synced and manual steps retain their values and progress action',
    (tester) async {
      final container = await _show(
        tester,
        scale: 2,
        health: _Health(connected: true),
        logs: {
          _todayKey: DailyLog(
            date: _todayKey,
            steps: 123456,
            stepsSource: 'healthConnect',
          ),
          '2026-09-18': DailyLog(
            date: '2026-09-18',
            steps: 8765,
            stepsSource: 'manual',
          ),
        },
      );
      expect(find.text('123,456 steps'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Connect'), findsNothing);
      expect(tester.takeException(), isNull);
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        18,
      );
      await tester.pumpAndSettle();
      expect(find.text('8,765 steps'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Connect'), findsNothing);
      final chart = find.byTooltip('View steps progress');
      await tester.ensureVisible(chart);
      final size = tester.getSize(chart);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(chart);
      await tester.pumpAndSettle();
      expect(find.text('Progress: steps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
