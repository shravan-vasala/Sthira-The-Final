import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_motion.dart';

enum ShareFormat { post, story }

enum ShareExportResult { success, dismissed, unavailable, failed }

class ShareCardExporter {
  /// Captures a given [widget], renders it offstage at a fixed size and scale,
  /// and exports it to a high-quality PNG.
  /// Post: 1080x1350 (logical 360x450 at 3x)
  /// Story: 1080x1920 (logical 360x640 at 3x)
  static Future<ShareExportResult> exportAndShareWidget({
    required BuildContext context,
    required Widget widget,
    required String fileName,
    required String text,
    ShareFormat format = ShareFormat.post,
  }) async {
    final logicalWidth = 360.0;
    final logicalHeight = format == ShareFormat.post ? 450.0 : 640.0;

    final boundaryKey = GlobalKey();

    // The widget we want to capture wrapped in a fixed media query so it ignores device scaling.
    final captureWidget = MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 900), // Max potential size
        devicePixelRatio: 1.0,
        textScaler: TextScaler.noScaling,
        padding: EdgeInsets.zero,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          // Inherit the current theme (e.g., Sthira specific themes)
          data: Theme.of(context),
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: logicalWidth,
              height: logicalHeight,
              child: widget,
            ),
          ),
        ),
      ),
    );

    // Mount it into the overlay
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -9999, // Safely off-screen
        top: -9999,
        width: logicalWidth,
        height: logicalHeight,
        child: Material(type: MaterialType.transparency, child: captureWidget),
      ),
    );

    overlayState.insert(overlayEntry);

    try {
      RenderRepaintBoundary? boundary;

      // Poll until the boundary is fully painted or timeout (max 2 seconds)
      for (int i = 0; i < 40; i++) {
        await Future.delayed(Motion.instant);
        boundary =
            boundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null && !boundary.debugNeedsPaint) {
          break;
        }
      }

      if (boundary == null || boundary.debugNeedsPaint) {
        throw Exception("Failed to render boundary in time.");
      }

      // Render it at 3x to get 1080 width exactly natively.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      image.dispose(); // Explicit RAM sweep post capturing bytes

      if (pngBytes == null) throw Exception("Failed to encode bytes");

      final tempDir = await getTemporaryDirectory();
      // Ensure unique filename
      final file = await File(
        '${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');

      // ignore: deprecated_member_use
      final result = await Share.shareXFiles([xFile], text: text);
      return switch (result.status) {
        ShareResultStatus.success => ShareExportResult.success,
        ShareResultStatus.dismissed => ShareExportResult.dismissed,
        ShareResultStatus.unavailable => ShareExportResult.unavailable,
      };
    } catch (e) {
      debugPrint('Error via ShareCardExporter: $e');
      return ShareExportResult.failed;
    } finally {
      overlayEntry.remove();
      overlayEntry.dispose();
    }
  }

  /// Legacy method for capturing directly from an active onscreen key.
  static Future<ShareExportResult> shareBoundary({
    required GlobalKey boundaryKey,
    required String fileName,
    required String text,
    double pixelRatio = 3.0,
    bool Function()? isCurrent,
  }) async {
    bool current() => isCurrent?.call() ?? true;
    File? preparedFile;
    try {
      if (!current()) return ShareExportResult.dismissed;
      final defaultBoundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (defaultBoundary == null) return ShareExportResult.failed;

      final image = await defaultBoundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      final pngBytes = byteData?.buffer.asUint8List();
      if (!current()) return ShareExportResult.dismissed;
      if (pngBytes == null) return ShareExportResult.failed;

      final tempDir = await getTemporaryDirectory();
      if (!current()) return ShareExportResult.dismissed;
      final file = File(
        '${tempDir.path}/${fileName}_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      preparedFile = file;
      await file.writeAsBytes(pngBytes);
      if (!current()) return ShareExportResult.dismissed;

      final xFile = XFile(file.path, mimeType: 'image/png');

      // ignore: deprecated_member_use
      final result = await Share.shareXFiles([xFile], text: text);
      return switch (result.status) {
        ShareResultStatus.success => ShareExportResult.success,
        ShareResultStatus.dismissed => ShareExportResult.dismissed,
        ShareResultStatus.unavailable => ShareExportResult.unavailable,
      };
    } catch (e) {
      debugPrint('Error sharing boundary: $e');
      return ShareExportResult.failed;
    } finally {
      if (!current() && preparedFile != null) {
        try {
          if (await preparedFile.exists()) await preparedFile.delete();
        } catch (_) {
          // A stale export never reaches the share sheet, even if cleanup fails.
        }
      }
    }
  }
}
