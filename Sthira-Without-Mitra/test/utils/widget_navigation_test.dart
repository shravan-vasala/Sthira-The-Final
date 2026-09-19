import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/utils/widget_navigation.dart';

void main() {
  test(
    'canonical actions normalize without carrying dates or account state',
    () {
      for (final action in widgetActions) {
        for (final raw in [
          'trufit://app/widget/$action',
          'trufit:///widget/$action',
          '/widget/$action',
          'trufit://app/widget/$action?date=2020-01-01&account=old#ignored',
        ]) {
          expect(widgetActionForUri(Uri.parse(raw)), action, reason: raw);
          expect(
            normalizeWidgetLocation(Uri.parse(raw)),
            '/widget/$action',
            reason: raw,
          );
        }
      }
    },
  );
  test('previously installed widget pending intents stay compatible', () {
    final legacy = {
      'trufit://home': 'home',
      'trufit://home/': 'home',
      'trufit://home/meals': 'meals',
      'trufit://home/workout/today': 'workout',
      'trufit://progress?metric=steps': 'steps',
    };
    for (final entry in legacy.entries) {
      expect(widgetActionForUri(Uri.parse(entry.key)), entry.value);
      expect(
        normalizeWidgetLocation(Uri.parse(entry.key)),
        '/widget/${entry.value}',
      );
    }
  });
  test('unrelated links and unknown widget actions are not hijacked', () {
    for (final raw in [
      'https://app/widget/home',
      'other://home/meals',
      'trufit://someone/widget/home',
      'trufit://app/widget/delete',
      '/widget/workout/extra',
      'trufit://progress?metric=weight',
      '/home/workout/monday',
      '/progress?metric=steps',
      'trufit://home/workout/yesterday',
    ]) {
      expect(widgetActionForUri(Uri.parse(raw)), isNull, reason: raw);
      expect(normalizeWidgetLocation(Uri.parse(raw)), isNull, reason: raw);
    }
  });
}
