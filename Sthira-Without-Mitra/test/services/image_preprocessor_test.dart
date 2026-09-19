import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:trufit_bodamma/services/image_preprocessor.dart';

void main() {
  test('prepared JPEG keeps the exact bytes and quality', () async {
    final bytes = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 320, height: 480), quality: 85),
    );
    final result = await ImagePreprocessor.processImage(bytes, 'image/jpeg');
    expect(result.$1, orderedEquals(bytes));
    expect(result.$2, 'image/jpeg');
    expect(result.$3, sha256.convert(bytes).toString());
  });

  test('small PNG is converted rather than mislabeled as JPEG', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 40, height: 30)),
    );
    final result = await ImagePreprocessor.processImage(bytes, 'image/png');
    final decoded = img.decodeJpg(result.$1);
    expect(decoded, isNotNull);
    expect(decoded!.width, 40);
    expect(decoded.height, 30);
    expect(result.$2, 'image/jpeg');
  });

  test('portrait images respect both dimensions and aspect ratio', () async {
    final bytes = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 700, height: 1400)),
    );
    final result = await ImagePreprocessor.processImage(bytes, 'image/jpeg');
    final decoded = img.decodeJpg(result.$1)!;
    expect(decoded.width, 512);
    expect(decoded.height, 1024);
  });

  test('unreadable images fail before being uploaded', () async {
    await expectLater(
      ImagePreprocessor.processImage(
        Uint8List.fromList([0, 1, 2]),
        'image/jpeg',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
