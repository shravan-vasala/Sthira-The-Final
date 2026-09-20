import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';
import 'package:trufit_bodamma/widgets/avatar_picker_sheet.dart';
import 'package:trufit_bodamma/widgets/profile_avatar.dart';

class _Media extends MediaRepository {
  _Media(this.base);
  final String base;
  @override
  String getAbsolutePath(String storedPath) => p.join(base, storedPath);
}

// Measures the actual illustration, including ears and antlers, instead of
// assuming a square image's nontransparent pixels fit inside a circle.
Future<double> _opaqueRadius(ui.Image image) async {
  final data = (await image.toByteData())!.buffer.asUint8List();
  var maximum = 0.0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (data[(y * image.width + x) * 4 + 3] < 128) continue;
      final dx = (x + .5 - image.width / 2) / (image.width / 2);
      final dy = (y + .5 - image.height / 2) / (image.height / 2);
      maximum = math.max(maximum, dx * dx + dy * dy);
    }
  }
  return math.sqrt(maximum);
}

void main() {
  testWidgets('every preset fits inside its circular border at app sizes', (
    tester,
  ) async {
    const sizes = [36.0, 44.0, 72.0];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final size in sizes)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final avatar in AvatarPickerSheet.avatars)
                        ProfileAvatar(
                          key: ValueKey('${avatar['name']}-$size'),
                          name: avatar['name']!,
                          photoPath: avatar['path'],
                          size: size,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() async {
      for (final avatar in AvatarPickerSheet.avatars) {
        await precacheImage(AssetImage(avatar['path']!), context);
      }
    });
    await tester.pumpAndSettle();

    final radii = <String, double>{};
    for (final size in sizes) {
      for (final avatar in AvatarPickerSheet.avatars) {
        final avatarFinder = find.byKey(ValueKey('${avatar['name']}-$size'));
        final rawFinder = find.descendant(
          of: avatarFinder,
          matching: find.byType(RawImage),
        );
        final rawImage = tester.widget<RawImage>(rawFinder);
        expect(rawImage.image, isNotNull, reason: avatar['name']);
        final radius =
            radii[avatar['name']] ??
            (await tester.runAsync(() => _opaqueRadius(rawImage.image!)))!;
        radii[avatar['name']!] = radius;

        final frame = tester.getRect(avatarFinder);
        final artwork = tester.getRect(rawFinder);
        expect((artwork.center - frame.center).distance, closeTo(0, .001));
        final borderWidth = size >= 64 ? 1.5 : 1.0;
        expect(
          radius * artwork.width / 2,
          lessThan(frame.width / 2 - borderWidth),
          reason: '${avatar['name']} must retain its full artwork at $size px',
        );
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('device photos fill the frame and remain circularly clipped', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('avatar_photo_fit_');
    addTearDown(() => directory.deleteSync(recursive: true));
    File(
      'assets/avatars/lion.png',
    ).copySync(p.join(directory.path, 'photo.png'));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaRepoProvider.overrideWithValue(_Media(directory.path)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: ProfileAvatar(
                name: 'Alex',
                photoPath: 'photo.png',
                size: 72,
              ),
            ),
          ),
        ),
      );
      await precacheImage(
        FileImage(File(p.join(directory.path, 'photo.png'))),
        tester.element(find.byType(ProfileAvatar)),
      );
    });
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(RawImage)),
      tester.getRect(find.byType(ProfileAvatar)),
    );
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    expect(
      find.ancestor(of: find.byType(RawImage), matching: find.byType(ClipOval)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('selected avatar marker stays inside its tile in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showAppBottomSheet<String>(
                    context: context,
                    builder: (_) => const AvatarPickerSheet(
                      currentAvatar: 'assets/avatars/lion.png',
                    ),
                  );
                },
                child: const Text('Choose avatar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose avatar'));
      await tester.pumpAndSettle();
      final tile = find.bySemanticsLabel('Select Lion');
      final marker = find.byIcon(Icons.check_circle_rounded);
      final tileRect = tester.getRect(tile);
      final markerRect = tester.getRect(marker);
      expect(tileRect.contains(markerRect.topLeft), isTrue);
      expect(tileRect.contains(markerRect.bottomRight), isTrue);
      expect(tileRect.width, greaterThanOrEqualTo(48));
      expect(tileRect.height, greaterThanOrEqualTo(48));
      await tester.tap(marker);
      await tester.pumpAndSettle();
      expect(selected, 'assets/avatars/lion.png');
      expect(tester.takeException(), isNull);
    });
  }
}
