import 'dart:async';
import 'dart:io';
// Platform test double for the existing image_picker plugin.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/screens/home/physique_pictures_screen.dart';
import 'package:trufit_bodamma/screens/home/photo_compare_screen.dart';
import 'package:trufit_bodamma/screens/home/photo_viewer_screen.dart';
import 'package:trufit_bodamma/screens/home/widgets/add_progress_photo_sheet.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

// Exercises the real screens with controlled account and photo records.
class _Media extends MediaRepository {
  String owner = 'first';
  final deletes = <String>[];
  final changes = StreamController<void>.broadcast();
  final photos = <ProgressPhoto>[
    ProgressPhoto(
      path: 'old-front.jpg',
      date: '2026-09-19',
      pose: 'front',
      weight: 80,
      note: 'My saved photo note',
    ),
    ProgressPhoto(
      path: 'old-side.jpg',
      date: '2026-08-18',
      pose: 'side',
      weight: 81,
    ),
  ];
  @override
  List<MapEntry<String, List<String>>> getAllProgressPhotos() => [
    for (final photo in photos) MapEntry(photo.date, [photo.path]),
  ];
  @override
  List<ProgressPhoto> getAllProgressPhotosDetailed() => photos;
  @override
  ProgressPhoto getProgressPhotoMeta(String date, String path) =>
      photos.where((p) => p.path == path).firstOrNull ??
      ProgressPhoto(path: path, date: date, pose: 'none');
  @override
  String getPoseTag(String path) => getProgressPhotoMeta('', path).pose;
  @override
  String getAbsolutePath(String path) => File(
    'test/fixtures/meal_scan/images/idli_chutney_1789715769511.jpg',
  ).absolute.path;
  @override
  Future<void> deletePhoto(String date, String path) async {
    deletes.add('$owner:$path');
    photos.removeWhere((p) => p.path == path);
  }
}

class _DeferredPicker extends ImagePickerPlatform {
  final result = Completer<XFile?>();
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    calls++;
    return result.future;
  }
}

class _PickedImage extends XFile {
  _PickedImage()
    : super(
        File(
          'test/fixtures/meal_scan/images/idli_chutney_1789715769511.jpg',
        ).absolute.path,
      );

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList([1, 2, 3]);
}

class _PendingSaveMedia extends _Media {
  final saved = Completer<String>();
  int saves = 0;

  @override
  Future<String> saveProgressPhoto(
    String date,
    Uint8List imageBytes, {
    String poseTag = 'none',
    double? weight,
    String? note,
  }) {
    saves++;
    return saved.future;
  }
}

class _Logs extends DailyLogRepository {
  @override
  DailyLog? getLog(String date) => DailyLog(date: date, weight: 80);
}

class _Profile extends ProfileNotifier {
  _Profile({this.useKg = false});
  final bool useKg;
  @override
  UserProfile build() => UserProfile(name: 'Alex', useKg: useKg);
}

Future<ProviderContainer> _show(
  WidgetTester tester,
  Widget page,
  _Media media, {
  double width = 390,
  double scale = 1,
  bool useKg = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      mediaRepoProvider.overrideWithValue(media),
      dailyLogRepoProvider.overrideWithValue(_Logs()),
      profileProvider.overrideWith(() => _Profile(useKg: useKg)),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
      progressPhotosStreamProvider.overrideWith((ref) {
        ref.watch(accountGenerationProvider);
        return media.changes.stream;
      }),
      allHabitsProvider.overrideWithValue([]),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(media.changes.close);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
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
    'viewer retires old photos and blocks a stale delete confirmation',
    (tester) async {
      final media = _Media();
      final container = await _show(
        tester,
        PhotoViewerScreen(
          photos: [
            for (final p in media.photos)
              PhotoItem(path: p.path, date: p.date, poseTag: p.pose),
          ],
          initialIndex: 0,
        ),
        media,
      );
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      media.owner = 'second';
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(media.deletes, isEmpty);
      expect(
        find.text('Account changed. Reopen your photos for this account.'),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'comparison retires old selections and share controls after account change',
    (tester) async {
      final media = _Media();
      final container = await _show(tester, const PhotoCompareScreen(), media);
      media.photos.clear();
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pumpAndSettle();
      media.changes.add(null);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sep 19, 2026'), findsNothing);
      expect(find.textContaining('Aug 18, 2026'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byTooltip('Share comparison'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('gallery and viewer use pounds and expose the saved photo note', (
    tester,
  ) async {
    final media = _Media();
    await _show(tester, const PhysiquePicturesScreen(), media);
    expect(find.text('80.0 kg'), findsNothing);
    expect(find.text('176.4 lb'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('progress-photo-old-front.jpg')),
    );
    await tester.pumpAndSettle();
    expect(find.text('My saved photo note'), findsOneWidget);
    expect(find.text('176.4 lb'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'one-photo comparison keeps its photo and opens the existing add flow',
    (tester) async {
      final media = _Media()..photos.removeLast();
      await _show(tester, const PhotoCompareScreen(), media);
      expect(find.text('Add a second photo'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.text('Add a second photo'));
      await tester.pumpAndSettle();
      expect(find.text('Add Progress Photo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('real-font add-photo and reference fit 320px at 200 percent', (
    tester,
  ) async {
    final media = _Media();
    await _show(
      tester,
      const Scaffold(body: AddProgressPhotoSheet()),
      media,
      width: 320,
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Front'));
    await tester.pumpAndSettle();
    expect(find.text('Match Angle'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Save Progress Photo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('real-font populated comparison fits 320px at 200 percent', (
    tester,
  ) async {
    final media = _Media();
    await _show(
      tester,
      const PhotoCompareScreen(),
      media,
      width: 320,
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Share comparison').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Slider'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gallery clears old selection when the account changes', (
    tester,
  ) async {
    final media = _Media();
    final container = await _show(
      tester,
      const PhysiquePicturesScreen(),
      media,
    );
    await tester.longPress(
      find.byKey(const ValueKey('progress-photo-old-front.jpg')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Selected'), findsOneWidget);
    media.photos.clear();
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('1 Selected'), findsNothing);
    expect(find.byTooltip('Delete selected photos'), findsNothing);
    expect(find.text('No progress photos yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('comparison picker hides stale thumbnails on account change', (
    tester,
  ) async {
    final media = _Media();
    final container = await _show(tester, const PhotoCompareScreen(), media);
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.text('Select Photo'), findsOneWidget);
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('Account changed'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gallery and viewer keep kilogram formatting consistent', (
    tester,
  ) async {
    final media = _Media();
    await _show(tester, const PhysiquePicturesScreen(), media, useKg: true);
    expect(find.text('80.0 kg'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('progress-photo-old-front.jpg')),
    );
    await tester.pumpAndSettle();
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(find.text('My saved photo note'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('zero-photo comparison has an existing capture action', (
    tester,
  ) async {
    final media = _Media()..photos.clear();
    await _show(tester, const PhotoCompareScreen(), media);
    expect(find.text('Add photo'), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Add photo').first);
    await tester.pumpAndSettle();
    expect(find.text('Add Progress Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saved photo note scrolls at 320px and 200 percent text', (
    tester,
  ) async {
    final media = _Media();
    media.photos[0] = ProgressPhoto(
      path: 'old-front.jpg',
      date: '2026-09-19',
      pose: 'front',
      weight: 80,
      note: List.filled(12, 'Saved context for this photo.').join(' '),
    );
    await _show(
      tester,
      PhotoViewerScreen(
        photos: [
          PhotoItem(
            path: 'old-front.jpg',
            date: '2026-09-19',
            poseTag: 'front',
          ),
        ],
        initialIndex: 0,
      ),
      media,
      width: 320,
      scale: 2,
    );
    expect(
      find.textContaining('Saved context for this photo.'),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final transitionOnly in [false, true]) {
    testWidgets(
      'late picker failure stays silent after account changes, transitionOnly=$transitionOnly',
      (tester) async {
        final original = ImagePickerPlatform.instance;
        final picker = _DeferredPicker();
        ImagePickerPlatform.instance = picker;
        addTearDown(() => ImagePickerPlatform.instance = original);
        final container = await _show(
          tester,
          const Scaffold(body: AddProgressPhotoSheet()),
          _Media(),
        );
        await tester.tap(find.text('Front'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Camera'));
        await tester.pump();
        expect(picker.calls, 1);
        if (transitionOnly) {
          container.read(accountTransitionProvider.notifier).state = true;
        } else {
          container.read(accountGenerationProvider.notifier).state++;
        }
        await tester.pump();
        picker.result.completeError(
          PlatformException(code: 'camera_access_denied'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Could not open the camera or gallery. Try again; your entries are kept.',
          ),
          findsNothing,
        );
        expect(find.byType(SnackBar), findsNothing);
        if (!transitionOnly) {
          expect(find.text('Account changed'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'late save failure does not show another account an error or a retry draft',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      final picker = _DeferredPicker();
      ImagePickerPlatform.instance = picker;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final media = _PendingSaveMedia();
      final container = await _show(
        tester,
        const Scaffold(body: AddProgressPhotoSheet()),
        media,
      );
      await tester.tap(find.text('Front'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery'));
      picker.result.complete(_PickedImage());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Progress Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Progress Photo'));
      await tester.pump();
      expect(media.saves, 1);
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      media.saved.completeError(StateError('Old account write failed'));
      await tester.pumpAndSettle();
      expect(find.text('Account changed'), findsOneWidget);
      expect(
        find.text(
          'Could not save your photo. Your entries are kept; please try again.',
        ),
        findsNothing,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
