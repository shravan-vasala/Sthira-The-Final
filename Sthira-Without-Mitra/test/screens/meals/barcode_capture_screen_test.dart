import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trufit_bodamma/screens/meals/widgets/barcode_capture_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Camera extends MobileScannerController {
  _Camera({this.denied = false, this.startGate}) : super(autoStart: false);

  final bool denied;
  final Completer<void>? startGate;
  final captures = StreamController<BarcodeCapture>.broadcast();
  int starts = 0;
  int stops = 0;
  bool wasDisposed = false;

  @override
  Stream<BarcodeCapture> get barcodes => captures.stream;

  @override
  Future<void> start({
    CameraFacing? cameraDirection,
    CameraLensType? cameraLensType,
  }) async {
    starts++;
    await startGate?.future;
    value = value.copyWith(
      isInitialized: true,
      isRunning: !denied,
      isStarting: false,
      size: const Size(640, 480),
      error: denied
          ? const MobileScannerException(
              errorCode: MobileScannerErrorCode.permissionDenied,
            )
          : null,
    );
  }

  @override
  Future<void> stop() async {
    if (value.isRunning) stops++;
    value = value.copyWith(isRunning: false);
  }

  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose() async {
    await stop();
    await captures.close();
    wasDisposed = true;
    await super.dispose();
  }
}

Future<void> _open(
  WidgetTester tester, {
  _Camera? camera,
  bool settle = true,
  required ValueChanged<String?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => BarcodeCaptureScreen(
                    controller: camera,
                    cameraSupported: camera != null,
                  ),
                ),
              );
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop fallback preserves leading zeros and validates length', (
    tester,
  ) async {
    String? result;
    await _open(tester, onResult: (value) => result = value);
    expect(
      find.textContaining('Camera scanning is not available'),
      findsOneWidget,
    );
    await tester.tap(find.text('Find food'));
    await tester.pump();
    expect(
      find.text('Enter all 8, 12, 13 or 14 barcode digits.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '0012345678905');
    await tester.ensureVisible(find.text('Find food'));
    await tester.tap(find.text('Find food'));
    await tester.pumpAndSettle();
    expect(result, '0012345678905');
  });

  testWidgets('camera returns one retail code and ignores QR detections', (
    tester,
  ) async {
    final camera = _Camera();
    final results = <String?>[];
    var haptics = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _open(tester, camera: camera, onResult: results.add);
    camera.captures.add(
      const BarcodeCapture(
        barcodes: [
          Barcode(
            rawValue: 'https://example.com',
            format: BarcodeFormat.qrCode,
          ),
        ],
      ),
    );
    await tester.pump();
    expect(results, isEmpty);
    const code = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: '8901058851323', format: BarcodeFormat.ean13),
      ],
    );
    camera.captures.add(code);
    camera.captures.add(code);
    await tester.pumpAndSettle();
    expect(results, ['8901058851323']);
    expect(haptics, 1);
    expect(camera.wasDisposed, isTrue);
    expect(camera.stops, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'UPC-E camera detections retain their expanded product identity',
    (tester) async {
      final camera = _Camera();
      String? result;
      await _open(tester, camera: camera, onResult: (value) => result = value);
      camera.captures.add(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: '04252614', format: BarcodeFormat.upcE)],
        ),
      );
      await tester.pumpAndSettle();
      expect(result, '042100005264');
    },
  );

  testWidgets('permission denial keeps manual entry available', (tester) async {
    final camera = _Camera(denied: true);
    String? result;
    await _open(tester, camera: camera, onResult: (value) => result = value);
    expect(
      find.textContaining('Allow camera access in device settings'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), '12345670');
    await tester.ensureVisible(find.text('Find food'));
    await tester.tap(find.text('Find food'));
    await tester.pumpAndSettle();
    expect(result, '12345670');
    expect(camera.wasDisposed, isTrue);
  });

  testWidgets('background pauses camera and resume restarts it', (
    tester,
  ) async {
    final camera = _Camera();
    await _open(tester, camera: camera, onResult: (_) {});
    expect(camera.value.isRunning, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(camera.value.isRunning, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(camera.value.isRunning, isTrue);
    expect(camera.starts, 2);
    await tester.tap(find.byTooltip('Cancel scanning'));
    await tester.pumpAndSettle();
    expect(camera.wasDisposed, isTrue);
  });

  testWidgets(
    'typing pauses camera and resume does not override manual entry',
    (tester) async {
      final camera = _Camera();
      await _open(tester, camera: camera, onResult: (_) {});
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      expect(camera.value.isRunning, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(camera.value.isRunning, isFalse);
      expect(
        find.text('Camera paused while you enter a barcode.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Use camera'));
      await tester.tap(find.text('Use camera'));
      await tester.pump();
      expect(camera.value.isRunning, isTrue);
      await tester.tap(find.byTooltip('Cancel scanning'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('leaving during camera startup releases a late camera session', (
    tester,
  ) async {
    final gate = Completer<void>();
    final camera = _Camera(startGate: gate);
    await _open(tester, camera: camera, settle: false, onResult: (_) {});
    await tester.pump(const Duration(milliseconds: 400));
    expect(camera.starts, 1);
    await tester.tap(find.byTooltip('Cancel scanning'));
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(camera.wasDisposed, isTrue);
    expect(camera.value.isRunning, isFalse);
    expect(camera.stops, 1);
  });

  testWidgets(
    'another route pauses camera until the scanner is visible again',
    (tester) async {
      final camera = _Camera();
      await _open(tester, camera: camera, onResult: (_) {});
      final navigator = Navigator.of(
        tester.element(find.byType(BarcodeCaptureScreen)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Other route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(camera.value.isRunning, isFalse);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(camera.value.isRunning, isTrue);
      await tester.tap(find.byTooltip('Cancel scanning'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('manual fallback fits a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const BarcodeCaptureScreen(cameraSupported: false),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Find food'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
