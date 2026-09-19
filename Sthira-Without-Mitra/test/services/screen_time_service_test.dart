import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/screen_time_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects malformed success readings without throwing', () {
    for (final payload in [
      {'status': 'success', 'minutes': '12', 'measuredDate': '2026-09-19'},
      {'status': 'success', 'minutes': -1, 'measuredDate': '2026-09-19'},
      {'status': 'success', 'minutes': 20, 'measuredDate': '2026-02-31'},
      {'status': 'success', 'minutes': 20, 'measuredDate': 42},
      {'status': [], 'error': {}},
    ]) {
      expect(ScreenTimeResult.fromJson(payload).status, 'failed');
    }
  });

  group('ScreenTimeResult parsing', () {
    test('Parses successful payload correctly', () {
      final json = {
        'status': 'success',
        'minutes': 142,
        'measuredDate': '2023-11-05',
        'timestamp': 1699142400000,
      };

      final result = ScreenTimeResult.fromJson(json);

      expect(result.status, 'success');
      expect(result.minutes, 142);
      expect(result.measuredDate, '2023-11-05');
      expect(result.timestamp, 1699142400000);
      expect(result.error, null);
    });

    test('Parses unavailable payload correctly', () {
      final json = {'status': 'unavailable'};

      final result = ScreenTimeResult.fromJson(json);

      expect(result.status, 'unavailable');
      expect(result.minutes, null);
      expect(result.measuredDate, null);
      expect(result.error, null);
    });

    test('Parses denied payload correctly', () {
      final json = {'status': 'denied'};

      final result = ScreenTimeResult.fromJson(json);

      expect(result.status, 'denied');
      expect(result.minutes, null);
    });

    test('Parses failed payload with error message', () {
      final json = {'status': 'failed', 'error': 'Remote exception occurred'};

      final result = ScreenTimeResult.fromJson(json);

      expect(result.status, 'failed');
      expect(result.error, 'Remote exception occurred');
    });

    test('Handles completely malformed fallback', () {
      final json = {'some_garbage': 0};

      final result = ScreenTimeResult.fromJson(json);

      // Defaults to failed if status is missing
      expect(result.status, 'failed');
    });
  });
}
