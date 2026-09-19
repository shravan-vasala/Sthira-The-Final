import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/main.dart';

void main() {
  test('real app entrypoint compiles', () {
    expect(const TruFitApp(), isA<TruFitApp>());
  });
}
