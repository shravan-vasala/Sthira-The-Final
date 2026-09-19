import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/services/diagnostic_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'persisted diagnostics are bounded and redacted before display and resave',
    () async {
      SharedPreferences.setMockInitialValues({
        'diagnostic_ring_buffer': jsonEncode([
          {
            'ts': '2026-09-19T12:00:00Z',
            'lvl': 'INFO',
            'msg': '?token=fixture_secret ${'x' * 10000}',
            'err': 'https://example.test/?password=private',
          },
          {'ts': 'invalid', 'lvl': 'INFO', 'msg': 'bad'},
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final logger = DiagnosticLogger(prefs);
      final entry = logger.getLogs().single;
      expect(entry.message.length, lessThan(4200));
      expect(entry.message, isNot(contains('fixture_secret')));
      expect(entry.error, isNot(contains('private')));
      await logger.flush();
      expect(
        prefs.getString('diagnostic_ring_buffer'),
        isNot(contains('fixture_secret')),
      );
      logger.dispose();
    },
  );
  test(
    'clear cannot be undone by queued older writes and subsequent logs persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final logger = DiagnosticLogger(prefs);
      logger.info('old');
      logger.clear();
      await logger.flush();
      expect(prefs.containsKey('diagnostic_ring_buffer'), isFalse);
      logger.info('new');
      await logger.flush();
      expect(prefs.getString('diagnostic_ring_buffer'), contains('new'));
      expect(prefs.getString('diagnostic_ring_buffer'), isNot(contains('old')));
      logger.dispose();
    },
  );
}
