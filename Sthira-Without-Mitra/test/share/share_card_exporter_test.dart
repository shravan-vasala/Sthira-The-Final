import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Platform doubles for the app's existing plugins.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:trufit_bodamma/share/share_card_exporter.dart';

class _Paths extends PathProviderPlatform {
  final String directory;
  final Completer<void>? reached;
  final Completer<void>? release;
  int calls = 0;

  _Paths(this.directory, {this.reached, this.release});

  @override
  Future<String?> getTemporaryPath() async {
    calls++;
    if (reached != null && !reached!.isCompleted) reached!.complete();
    if (release != null) await release!.future;
    return directory;
  }
}

class _Shares extends SharePlatform {
  final calls = <ShareParams>[];
  Uint8List? bytes;

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    bytes = await File(params.files!.single.path).readAsBytes();
    return const ShareResult('test-destination', ShareResultStatus.success);
  }

  void reset() {
    calls.clear();
    bytes = null;
  }
}

Future<GlobalKey> _paintBoundary(WidgetTester tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 100,
              height: 80,
              child: ColoredBox(color: Color(0xff38664c)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharePlatform originalShares;
  late PathProviderPlatform originalPaths;
  final shares = _Shares();

  setUpAll(() {
    // SharePlus.instance captures its platform once, so use one double for this
    // test isolate and clear only its observations between cases.
    originalShares = SharePlatform.instance;
    originalPaths = PathProviderPlatform.instance;
    SharePlatform.instance = shares;
  });
  setUp(shares.reset);
  tearDownAll(() {
    SharePlatform.instance = originalShares;
    PathProviderPlatform.instance = originalPaths;
  });

  testWidgets('pre-stale export is dismissed before preparing or sharing', (
    tester,
  ) async {
    final key = await _paintBoundary(tester);
    await tester.runAsync(() async {
      final temporary = await Directory.systemTemp.createTemp(
        'sthira_share_stale_',
      );
      try {
        final paths = _Paths(temporary.path);
        PathProviderPlatform.instance = paths;
        final result = await ShareCardExporter.shareBoundary(
          boundaryKey: key,
          fileName: 'comparison',
          text: 'My comparison',
          pixelRatio: 1,
          isCurrent: () => false,
        );
        expect(result, ShareExportResult.dismissed);
        expect(paths.calls, 0);
        expect(shares.calls, isEmpty);
        expect(await temporary.list().toList(), isEmpty);
      } finally {
        await temporary.delete(recursive: true);
      }
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'account change during asynchronous export prevents native sharing',
    (tester) async {
      final key = await _paintBoundary(tester);
      await tester.runAsync(() async {
        final temporary = await Directory.systemTemp.createTemp(
          'sthira_share_account_',
        );
        final reached = Completer<void>();
        final release = Completer<void>();
        var current = true;
        Future<ShareExportResult>? pending;
        try {
          final paths = _Paths(
            temporary.path,
            reached: reached,
            release: release,
          );
          PathProviderPlatform.instance = paths;
          pending = ShareCardExporter.shareBoundary(
            boundaryKey: key,
            fileName: 'comparison',
            text: 'Old account comparison',
            pixelRatio: 1,
            isCurrent: () => current,
          );
          // Reaching path lookup proves that a real boundary was captured and
          // encoded. Switch accounts while its asynchronous preparation waits.
          await reached.future.timeout(const Duration(seconds: 10));
          expect(shares.calls, isEmpty);
          current = false;
          release.complete();
          expect(
            await pending.timeout(const Duration(seconds: 10)),
            ShareExportResult.dismissed,
          );
          expect(paths.calls, 1);
          expect(shares.calls, isEmpty);
          expect(await temporary.list().toList(), isEmpty);
        } finally {
          current = false;
          if (!release.isCompleted) release.complete();
          if (pending != null)
            await pending.timeout(const Duration(seconds: 10));
          await temporary.delete(recursive: true);
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('current account export shares the actual captured PNG', (
    tester,
  ) async {
    final key = await _paintBoundary(tester);
    await tester.runAsync(() async {
      final temporary = await Directory.systemTemp.createTemp(
        'sthira_share_current_',
      );
      try {
        PathProviderPlatform.instance = _Paths(temporary.path);
        final result = await ShareCardExporter.shareBoundary(
          boundaryKey: key,
          fileName: 'comparison',
          text: 'My comparison',
          pixelRatio: 1,
          isCurrent: () => true,
        );
        expect(result, ShareExportResult.success);
        expect(shares.calls, hasLength(1));
        expect(shares.calls.single.text, 'My comparison');
        expect(shares.calls.single.files!.single.mimeType, 'image/png');
        final bytes = shares.bytes!;
        expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
        final header = ByteData.sublistView(bytes);
        expect(header.getUint32(16), 100);
        expect(header.getUint32(20), 80);
        expect(await temporary.list().toList(), hasLength(1));
      } finally {
        await temporary.delete(recursive: true);
      }
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
