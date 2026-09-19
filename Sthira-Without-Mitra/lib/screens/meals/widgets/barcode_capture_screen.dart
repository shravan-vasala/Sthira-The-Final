import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Captures a retail barcode and returns its digits to the calling route.
class BarcodeCaptureScreen extends StatefulWidget {
  const BarcodeCaptureScreen({
    super.key,
    this.controller,
    this.cameraSupported,
  });

  /// An injected controller must have autoStart disabled. This screen owns it.
  @visibleForTesting
  final MobileScannerController? controller;

  @visibleForTesting
  final bool? cameraSupported;

  @override
  State<BarcodeCaptureScreen> createState() => _BarcodeCaptureScreenState();
}

class _BarcodeCaptureScreenState extends State<BarcodeCaptureScreen>
    with WidgetsBindingObserver {
  static final _digits = RegExp(r'^(?:[0-9]{8}|[0-9]{12,14})$');
  static const _formats = [
    BarcodeFormat.ean8,
    BarcodeFormat.ean13,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  ];

  final _barcode = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _form = GlobalKey<FormState>();
  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  Future<void> _cameraWork = Future<void>.value();
  AppLifecycleState? _lifecycle;
  bool _routeCurrent = true;
  bool _manualMode = false;
  bool _completed = false;
  String? _cameraFailure;

  bool get _cameraSupported =>
      widget.cameraSupported ??
      (kIsWeb ||
          switch (defaultTargetPlatform) {
            TargetPlatform.android ||
            TargetPlatform.iOS ||
            TargetPlatform.macOS => true,
            _ => false,
          });

  bool get _shouldRun =>
      mounted &&
      !_completed &&
      !_manualMode &&
      _routeCurrent &&
      (_lifecycle == null || _lifecycle == AppLifecycleState.resumed);

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
    _barcodeFocus.addListener(() {
      if (_barcodeFocus.hasFocus) _useManualEntry();
    });
    if (_cameraSupported) {
      _controller =
          widget.controller ??
          MobileScannerController(
            autoStart: false,
            formats: _formats,
            detectionSpeed: DetectionSpeed.noDuplicates,
          );
      assert(!_controller!.autoStart);
      _subscription = _controller!.barcodes.listen(
        _onDetect,
        onError: (Object error, StackTrace stackTrace) {
          if (mounted && !_completed) {
            setState(
              () => _cameraFailure =
                  'Scanning was interrupted. Try again or enter the barcode below.',
            );
            _syncCamera();
          }
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCamera();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    if (_routeCurrent != current) {
      _routeCurrent = current;
      _syncCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    // Permission prompts also change lifecycle. Serialize the pending start
    // before stopping, and evaluate the latest state once permission returns.
    _syncCamera();
  }

  void _syncCamera({bool retry = false}) {
    final controller = _controller;
    if (controller == null) return;
    _cameraWork = _cameraWork
        .then((_) async {
          if (!_shouldRun || (_cameraFailure != null && !retry)) {
            await controller.stop();
            return;
          }
          if (!retry && controller.value.error != null) {
            return;
          }
          if (!controller.value.isRunning) await controller.start();
          // The route can disappear while the camera permission dialog is open.
          if (!_shouldRun) await controller.stop();
        })
        .catchError((Object error) {
          if (mounted && !_completed) {
            setState(
              () => _cameraFailure =
                  'The camera could not start. '
                  'Try again or enter the barcode below.',
            );
          }
        });
  }

  void _useCamera() {
    _barcodeFocus.unfocus();
    setState(() {
      _manualMode = false;
      _cameraFailure = null;
    });
    _syncCamera(retry: true);
  }

  void _useManualEntry() {
    if (_manualMode) return;
    setState(() => _manualMode = true);
    _syncCamera();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_shouldRun) return;
    for (final barcode in capture.barcodes) {
      if (!_formats.contains(barcode.format)) continue;
      var value = barcode.rawValue?.trim();
      if (value == null || !_digits.hasMatch(value)) continue;
      if (barcode.format == BarcodeFormat.upcE && value.length == 8) {
        value = _expandUpcE(value);
      }
      _finish(value);
      return;
    }
  }

  // UPC-E is a compressed UPC-A, not an EAN-8. Preserve that identity before
  // handing digits to lookup. Expansion follows the standard UPC-E rules.
  String _expandUpcE(String code) {
    final payload = code.substring(1, 7);
    final last = payload[5];
    final expanded = switch (last) {
      '0' ||
      '1' ||
      '2' => '${payload.substring(0, 2)}${last}0000${payload.substring(2, 5)}',
      '3' => '${payload.substring(0, 3)}00000${payload.substring(3, 5)}',
      '4' => '${payload.substring(0, 4)}00000${payload[4]}',
      _ => '${payload.substring(0, 5)}0000$last',
    };
    return '${code[0]}$expanded${code[7]}';
  }

  void _submitManual() {
    if (_form.currentState?.validate() ?? false) {
      _finish(_barcode.text.trim());
    }
  }

  void _finish(String value) {
    if (_completed || !mounted) return;
    _completed = true;
    _barcodeFocus.unfocus();
    _syncCamera();
    if (!kIsWeb) unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop(value);
  }

  void _cancel() {
    if (_completed) return;
    _completed = true;
    _syncCamera();
    Navigator.of(context).pop();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller?.toggleTorch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The flashlight is unavailable.')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _completed = true;
    unawaited(_subscription?.cancel());
    _barcode.dispose();
    _barcodeFocus.dispose();
    final controller = _controller;
    if (controller != null) {
      // Wait for an outstanding permission/start request before releasing the
      // camera, so a late start cannot leave it active behind the next screen.
      unawaited(
        _cameraWork.then((_) => controller.dispose()).catchError((
          Object error,
        ) {
          // The route is already gone; a platform teardown failure must not
          // surface as an unhandled asynchronous exception.
        }),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope<String>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _completed = true;
          _syncCamera();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan barcode'),
          leading: IconButton(
            tooltip: 'Cancel scanning',
            onPressed: _cancel,
            icon: const Icon(Icons.close),
          ),
          actions: [
            if (controller != null)
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, _) => IconButton(
                  tooltip: state.torchState == TorchState.on
                      ? 'Turn flashlight off'
                      : 'Turn flashlight on',
                  onPressed:
                      state.isRunning &&
                          state.torchState != TorchState.unavailable
                      ? _toggleTorch
                      : null,
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flashlight_off_outlined
                        : Icons.flashlight_on_outlined,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Find the barcode on the pack.',
                  style: context.text.cardTitle,
                ),
                const SizedBox(height: Spacing.textPair),
                Text(
                  controller == null
                      ? 'Enter the printed numbers to find your food.'
                      : 'Keep the whole barcode in view and hold steady.',
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                const SizedBox(height: Spacing.block),
                if (controller == null)
                  _cameraMessage(
                    icon: Icons.barcode_reader,
                    message:
                        'Camera scanning is not available on this device. '
                        'You can still enter the barcode below.',
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.card),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: controller,
                            placeholderBuilder: (context) => ColoredBox(
                              color: context.colors.insetSurface,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: 'Starting camera',
                                ),
                              ),
                            ),
                            errorBuilder: (context, error) => _cameraMessage(
                              icon: Icons.no_photography_outlined,
                              message:
                                  error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
                                  ? 'Allow camera access in device settings, '
                                        'then try again. Or enter the barcode below.'
                                  : 'The camera is unavailable. Try again or '
                                        'enter the barcode below.',
                              retry: true,
                            ),
                            overlayBuilder: (context, constraints) =>
                                IgnorePointer(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      Spacing.section,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.colors.white,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Radii.chip,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                          if (_manualMode)
                            _cameraMessage(
                              icon: Icons.keyboard_outlined,
                              message:
                                  'Camera paused while you enter a barcode.',
                              retry: true,
                              retryLabel: 'Use camera',
                            )
                          else if (_cameraFailure != null)
                            _cameraMessage(
                              icon: Icons.no_photography_outlined,
                              message: _cameraFailure!,
                              retry: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.section),
                Form(
                  key: _form,
                  child: TextFormField(
                    controller: _barcode,
                    focusNode: _barcodeFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 14,
                    onTap: _useManualEntry,
                    onFieldSubmitted: (_) => _submitManual(),
                    decoration: const InputDecoration(
                      labelText: 'Barcode number',
                      helperText:
                          'The 8, 12, 13 or 14 digits printed on the pack',
                      helperMaxLines: 3,
                      errorMaxLines: 3,
                      counterText: '',
                    ),
                    validator: (value) => _digits.hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Enter all 8, 12, 13 or 14 barcode digits.',
                  ),
                ),
                const SizedBox(height: Spacing.block),
                ElevatedButton(
                  onPressed: _submitManual,
                  child: const Text('Find food'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraMessage({
    required IconData icon,
    required String message,
    bool retry = false,
    String retryLabel = 'Try camera again',
  }) => ColoredBox(
    color: context.colors.insetSurface,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.block),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: IconSize.hero, color: context.colors.textMedium),
            const SizedBox(height: Spacing.inline),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.body,
            ),
            if (retry) ...[
              const SizedBox(height: Spacing.inline),
              TextButton(onPressed: _useCamera, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    ),
  );
}
