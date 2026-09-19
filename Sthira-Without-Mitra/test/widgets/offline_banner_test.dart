import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/offline_banner.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('General Sans')
      ..addFont(rootBundle.load('assets/fonts/GeneralSans-Medium.ttf'));
    await fonts.load();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'offline message is readable and announced in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final palette = dark ? AppColors.dark : AppColors.light;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 700),
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ColoredBox(
                      color: palette.card,
                      child: const OfflineBanner(),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          const copy =
              'You are offline. AI scanning needs a connection. Saved meals stay available.';
          expect(find.text(copy), findsOneWidget);
          final text = tester.widget<Text>(find.text(copy));
          final fill = tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(OfflineBanner),
                  matching: find.byType(Container),
                ),
              )
              .color!;
          final paintedFill = Color.alphaBlend(fill, palette.card);
          expect(
            _contrast(text.style!.color!, paintedFill),
            greaterThanOrEqualTo(4.5),
          );
          final icon = tester.widget<Icon>(find.byIcon(Icons.wifi_off_rounded));
          expect(_contrast(icon.color!, paintedFill), greaterThanOrEqualTo(3));
          final notice = tester.getSemantics(find.byType(OfflineBanner));
          expect(
            notice.getSemanticsData().flagsCollection.isLiveRegion,
            isTrue,
          );
          expect(notice.label, contains(copy));
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'custom offline details remain intact and the band does not block local controls',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(
                  message: 'Connection unavailable. Your draft is kept.',
                ),
                TextButton(
                  onPressed: () => tapped = true,
                  child: const Text('Keep editing'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.text('Connection unavailable. Your draft is kept.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep editing'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
