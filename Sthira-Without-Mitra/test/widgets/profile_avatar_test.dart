import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/profile_avatar.dart';

class _Media extends MediaRepository {
  _Media(this.base);
  String base;
  final requested = <String>[];
  @override
  String getAbsolutePath(String storedPath) {
    requested.add(storedPath);
    if (storedPath.contains('..')) throw ArgumentError('Invalid stored path');
    return p.join(base, storedPath);
  }
}

Widget _app(
  ProviderContainer container, {
  String? photoPath,
  String name = 'Alex Vasala',
  double size = 44,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: ProfileAvatar(name: name, photoPath: photoPath, size: size),
    ),
  ),
);

void main() {
  testWidgets(
    'relative restored photos resolve through media repository and refresh per account',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('profile_avatar_');
      addTearDown(() => directory.deleteSync(recursive: true));
      const stored = 'profile/photo.png';
      for (final account in ['a', 'b']) {
        final file = File(p.join(directory.path, account, stored));
        file.parent.createSync(recursive: true);
        File('assets/avatars/lion.png').copySync(file.path);
      }
      final media = _Media(p.join(directory.path, 'a'));
      final container = ProviderContainer(
        overrides: [mediaRepoProvider.overrideWithValue(media)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container, photoPath: stored, size: 72));
      var image = tester.widget<Image>(find.byType(Image));
      expect((image.image as FileImage).file.path, p.join(media.base, stored));
      expect(media.requested, contains(stored));
      final originalKey = image.key;
      media.base = p.join(directory.path, 'b');
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      image = tester.widget<Image>(find.byType(Image));
      expect((image.image as FileImage).file.path, p.join(media.base, stored));
      expect(image.key, isNot(originalKey));
      container.read(accountTransitionProvider.notifier).state = true;
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('AV'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('presets use assets and invalid stored paths retain initials', (
    tester,
  ) async {
    final media = _Media('unused');
    final container = ProviderContainer(
      overrides: [mediaRepoProvider.overrideWithValue(media)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _app(container, photoPath: 'assets/avatars/owl.png'),
    );
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    expect(media.requested, isEmpty);
    await tester.pumpWidget(
      _app(
        container,
        photoPath: '../missing.png',
        name: '  Alexandra Catherine Vasala  ',
      ),
    );
    expect(find.text('AV'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('truncated local photo falls back after its image load fails', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'profile_avatar_corrupt_',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    File(p.join(directory.path, 'broken.png')).writeAsBytesSync([]);
    final media = _Media(directory.path);
    final container = ProviderContainer(
      overrides: [mediaRepoProvider.overrideWithValue(media)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(_app(container, photoPath: 'broken.png'));
      final failed = Completer<void>();
      final provider = tester.widget<Image>(find.byType(Image)).image;
      final stream = provider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (image, synchronous) => failed.completeError(
          StateError('Truncated image unexpectedly decoded'),
        ),
        onError: (Object error, StackTrace? stack) => failed.complete(),
      );
      stream.addListener(listener);
      try {
        await failed.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-avatar-fallback')),
      findsOneWidget,
    );
    expect(find.text('AV'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
