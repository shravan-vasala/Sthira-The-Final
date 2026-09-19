import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  /// Keeps prepared JPEGs byte-for-byte. All codec/hash work runs off the UI
  /// isolate; other formats are normalized so the advertised MIME is correct.
  static Future<(Uint8List, String, String)> processImage(
    Uint8List bytes,
    String fallbackMimeType,
  ) => compute(_process, bytes);

  static (Uint8List, String, String) _process(Uint8List bytes) {
    try {
      return _decode(bytes);
    } catch (_) {
      throw const FormatException(
        'This photo could not be read. Try another JPEG or PNG.',
      );
    }
  }

  static (Uint8List, String, String) _decode(Uint8List bytes) {
    final jpeg = img.JpegDecoder().startDecode(bytes);
    if (jpeg != null &&
        jpeg.width <= 1024 &&
        jpeg.height <= 1024 &&
        bytes.length < 1024 * 1024) {
      return (bytes, 'image/jpeg', sha256.convert(bytes).toString());
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException(
        'This photo format could not be read. Try a JPEG or PNG.',
      );
    }
    var image = img.bakeOrientation(decoded);
    if (image.width > 1024 || image.height > 1024) {
      final scale = 1024 / math.max(image.width, image.height);
      image = img.copyResize(
        image,
        width: math.max(1, (image.width * scale).round()),
        height: math.max(1, (image.height * scale).round()),
      );
    }
    final bytesOut = Uint8List.fromList(img.encodeJpg(image, quality: 85));
    return (bytesOut, 'image/jpeg', sha256.convert(bytesOut).toString());
  }
}
