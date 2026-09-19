import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Platform test double for the already-declared image_picker plugin.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/screens/home/physique_pictures_screen.dart';
import 'package:trufit_bodamma/screens/home/photo_compare_screen.dart';
import 'package:trufit_bodamma/screens/home/widgets/add_progress_photo_sheet.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_navigation_bar.dart';
import 'package:trufit_bodamma/widgets/rest_timer_bar.dart';

class _Media extends MediaRepository {
  final photos = <ProgressPhoto>[
    ProgressPhoto(
      path: 'front.jpg',
      date: '2026-09-19',
      pose: 'front',
      weight: 80,
    ),
    ProgressPhoto(
      path: 'side.jpg',
      date: '2026-09-18',
      pose: 'side',
      weight: 81,
    ),
  ];
  final deleted = <Map<String, List<String>>>[];
  @override
  List<MapEntry<String, List<String>>> getAllProgressPhotos() => [
    for (final photo in photos) MapEntry(photo.date, [photo.path]),
  ];
  @override
  List<ProgressPhoto> getAllProgressPhotosDetailed() => [];
  @override
  ProgressPhoto getProgressPhotoMeta(String date, String path) =>
      photos.firstWhere((photo) => photo.path == path);
  @override
  String getPoseTag(String path) =>
      photos.firstWhere((photo) => photo.path == path).pose;
  @override
  String getAbsolutePath(String path) => 'missing-photo-fixture/$path';
  @override
  Future<void> deletePhotos(Map<String, List<String>> selection) async {
    deleted.add({
      for (final entry in selection.entries) entry.key: List.from(entry.value),
    });
    final paths = selection.values.expand((paths) => paths).toSet();
    photos.removeWhere((photo) => paths.contains(photo.path));
  }
}

class _Logs extends DailyLogRepository {
  @override
  DailyLog? getLog(String date) => DailyLog(date: date, weight: 80);
}

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alex', useKg: false);
}

class _FailingPicker extends ImagePickerPlatform {
  int attempts = 0;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    attempts++;
    throw PlatformException(code: 'camera_access_denied');
  }
}

Future<ProviderContainer> _show(
  WidgetTester tester,
  Widget page,
  _Media repo, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool withDock = false,
  bool timer = false,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      mediaRepoProvider.overrideWithValue(repo),
      dailyLogRepoProvider.overrideWithValue(_Logs()),
      profileProvider.overrideWith(_Profile.new),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
      progressPhotosStreamProvider.overrideWith(
        (ref) => const Stream<void>.empty(),
      ),
      allHabitsProvider.overrideWithValue([]),
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
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: withDock
                ? EdgeInsets.only(bottom: keyboard > 0 ? 0 : 34)
                : null,
            viewPadding: withDock ? const EdgeInsets.only(bottom: 34) : null,
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: withDock
            ? Scaffold(
                extendBody: true,
                body: page,
                bottomNavigationBar: AppNavigationDock(
                  currentIndex: 0,
                  onItemSelected: (_) {},
                  restTimer: timer
                      ? RestTimerBar(
                          remainingSeconds: 75,
                          isPaused: false,
                          exerciseName: 'Dumbbell rows',
                          onAddSeconds: (_) {},
                          onTogglePause: () {},
                          onClose: () {},
                        )
                      : null,
                ),
              )
            : page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bulk delete confirmation is safe after leaving the gallery', (
    tester,
  ) async {
    final repo = _Media();
    final showGallery = ValueNotifier(true);
    addTearDown(showGallery.dispose);
    await _show(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: showGallery,
        builder: (context, visible, child) => visible
            ? const PhysiquePicturesScreen()
            : const Scaffold(body: Text('Another destination')),
      ),
      repo,
    );
    await tester.longPress(
      find.byKey(const ValueKey('progress-photo-front.jpg')),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('Delete selected photos'));
    expect(find.text('Delete Photos?'), findsOneWidget);
    // The confirmation uses the root navigator and can outlive its gallery.
    showGallery.value = false;
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isEmpty);
    expect(find.text('Delete Photos?'), findsNothing);
    expect(find.text('Another destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('first photo action clears the active dock at 320/200%', (
    tester,
  ) async {
    await _show(
      tester,
      const PhysiquePicturesScreen(),
      _Media()..photos.clear(),
      size: const Size(320, 844),
      scale: 2,
      withDock: true,
      timer: true,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    final action = find.widgetWithText(ElevatedButton, 'Take First Photo');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(action).bottom,
      lessThan(tester.getRect(find.byType(RestTimerBar)).top),
    );
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(AddProgressPhotoSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final timer in [false, true]) {
    testWidgets(
      'photo action and final tile clear dock at 320/200%, timer=$timer',
      (tester) async {
        await _show(
          tester,
          const PhysiquePicturesScreen(),
          _Media(),
          size: const Size(320, 844),
          scale: 2,
          withDock: true,
          timer: timer,
        );
        final action = find.byType(FloatingActionButton);
        final footer = timer
            ? find.byType(RestTimerBar)
            : find.byType(AppNavigationBar);
        expect(
          tester.getRect(action).bottom,
          lessThan(tester.getRect(footer).top),
        );
        final list = find.byType(ListView).first;
        final scroll = tester
            .state<ScrollableState>(
              find
                  .descendant(of: list, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        scroll.jumpTo(scroll.maxScrollExtent);
        await tester.pumpAndSettle();
        final lastPhoto = find.byKey(const ValueKey('progress-photo-side.jpg'));
        expect(lastPhoto, findsOneWidget);
        expect(
          tester.getRect(lastPhoto).bottom,
          lessThan(tester.getRect(action).top),
        );
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(AddProgressPhotoSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'photo action uses keyboard clearance without adding the dock twice',
    (tester) async {
      await _show(
        tester,
        const PhysiquePicturesScreen(),
        _Media(),
        withDock: true,
        timer: true,
        keyboard: 300,
      );
      expect(find.byType(AppNavigationBar), findsNothing);
      final bottom = tester.getRect(find.byType(FloatingActionButton)).bottom;
      expect(bottom, lessThanOrEqualTo(844 - 300));
      expect(bottom, greaterThan(844 - 300 - 60));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'deleting after changing the pose filter retains every selected photo',
    (tester) async {
      final repo = _Media();
      await _show(tester, const PhysiquePicturesScreen(), repo);
      await tester.longPress(
        find.byKey(const ValueKey('progress-photo-front.jpg')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('progress-photo-side.jpg')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('progress-photo-side.jpg')));
      expect(find.text('2 Selected'), findsOneWidget);
      await _tap(tester, find.text('Front · 1'));
      expect(
        find.byKey(const ValueKey('progress-photo-side.jpg')),
        findsNothing,
      );
      await _tap(tester, find.byTooltip('Delete selected photos'));
      expect(
        find.text("Delete 2 photo(s)? This can't be undone."),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(ElevatedButton, 'Delete'));
      expect(repo.deleted, [
        {
          '2026-09-19': ['front.jpg'],
          '2026-09-18': ['side.jpg'],
        },
      ]);
      expect(repo.photos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an account change while delete confirmation is open blocks deletion',
    (tester) async {
      final repo = _Media();
      final container = await _show(
        tester,
        const PhysiquePicturesScreen(),
        repo,
      );
      await tester.longPress(
        find.byKey(const ValueKey('progress-photo-front.jpg')),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Delete selected photos'));
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      await _tap(tester, find.widgetWithText(ElevatedButton, 'Delete'));
      expect(repo.deleted, isEmpty);
      expect(repo.photos, hasLength(2));
      expect(find.text('Delete Photos?'), findsNothing);
    },
  );
  testWidgets(
    'comparison controls fit 320px at 200% text and slider is adjustable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _show(
          tester,
          const PhotoCompareScreen(),
          _Media(),
          size: const Size(320, 844),
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.byTooltip('Swap photos').hitTestable(), findsOneWidget);
        expect(
          find.byTooltip('Share comparison').hitTestable(),
          findsOneWidget,
        );
        await _tap(tester, find.text('Slider'));
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(
          slider.semanticFormatterCallback!(.75),
          '75 percent first photo',
        );
        slider.onChanged!(.75);
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(find.byType(Slider)).value, .75);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'camera failure keeps the chosen pose and draft values in profile units',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      final picker = _FailingPicker();
      ImagePickerPlatform.instance = picker;
      addTearDown(() => ImagePickerPlatform.instance = original);
      await _show(
        tester,
        const Scaffold(body: AddProgressPhotoSheet()),
        _Media(),
      );
      final weight = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.labelText?.startsWith('Weight (lb,') ?? false),
      );
      final note = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Note (Optional)',
      );
      expect(weight, findsOneWidget);
      expect(tester.widget<TextField>(weight).controller!.text, '176.4');
      await tester.enterText(weight, '175.0');
      await tester.enterText(note, 'After my walk');
      await _tap(tester, find.text('Front'));
      await _tap(tester, find.text('Camera'));
      expect(
        find.text(
          'Could not open the camera or gallery. Try again; your entries are kept.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(weight).controller!.text, '175.0');
      expect(tester.widget<TextField>(note).controller!.text, 'After my walk');
      await _tap(tester, find.text('Camera'));
      expect(picker.attempts, 2);
      expect(find.text('Please select a pose first.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
