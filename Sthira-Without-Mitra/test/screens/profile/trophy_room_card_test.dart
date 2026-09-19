import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show SemanticsAction, SemanticsFlag;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/badge.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/screens/profile/widgets/trophy_room_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _lockedBadge = Badge(
  id: 'steady',
  category: 'streak',
  title: 'A steady habit for a healthier tomorrow',
  description: 'Track your habits for thirty days.',
  iconEmoji: '★',
  requiredProgress: 30,
  currentProgress: 12,
);
final _unlockedBadge = Badge(
  id: 'first',
  category: 'workout',
  title: 'Your first meaningful milestone',
  description: 'Complete your first workout.',
  iconEmoji: '★',
  requiredProgress: 1,
  currentProgress: 1,
  unlockedAt: DateTime(2026, 9, 19),
);

Future<void> _pumpTrophies(
  WidgetTester tester, {
  required double width,
  required double textScale,
  required ThemeData theme,
  List<Badge>? badges,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        badgesProvider.overrideWithValue(
          badges ?? [_unlockedBadge, _lockedBadge],
        ),
      ],
      child: MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: TrophyRoomCard(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'trophy names remain complete on narrow screens with large text',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        for (final scale in [1.0, 2.0, 3.0]) {
          await _pumpTrophies(
            tester,
            width: 320,
            textScale: scale,
            theme: theme,
          );
          expect(tester.takeException(), isNull);
          for (final badge in [_unlockedBadge, _lockedBadge]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(badge.title),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
          }
        }
      }
    },
  );

  testWidgets('trophies expose status and open details from the keyboard', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpTrophies(
        tester,
        width: 390,
        textScale: 1,
        theme: AppTheme.light,
        badges: [_lockedBadge],
      );

      final badgeSemantics = tester
          .getSemantics(
            find.bySemanticsLabel(
              '${_lockedBadge.title}. Locked. 12 of 30 completed',
            ),
          )
          .getSemanticsData();
      expect(badgeSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(badgeSemantics.hasAction(SemanticsAction.tap), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('HOW TO EARN:'), findsOneWidget);
      expect(find.text('Track your habits for thirty days.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  if (const bool.fromEnvironment('UI_PREVIEW')) {
    testWidgets('Render trophy shelf with bundled brand fonts', (tester) async {
      // Headless Flutter tests have no platform emoji fallback. Supply a local
      // font for review images only; no system font is bundled with the app.
      final emojiPath = Platform.environment['UI_EMOJI_FONT'];
      if (emojiPath != null) {
        final emoji = FontLoader('Preview Emoji')
          ..addFont(
            Future.value(
              ByteData.sublistView(File(emojiPath).readAsBytesSync()),
            ),
          );
        await emoji.load();
      }

      for (final entry in {
        'Cabinet Grotesk': ['CabinetGrotesk-Bold', 'CabinetGrotesk-Extrabold'],
        'General Sans': [
          'GeneralSans-Medium',
          'GeneralSans-Semibold',
          'GeneralSans-Bold',
        ],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final font in entry.value) {
          loader.addFont(rootBundle.load('assets/fonts/$font.ttf'));
        }
        await loader.load();
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final variant in [
        (name: 'dark', dark: true, width: 390.0, height: 560.0, scale: 1.0),
        (name: 'light', dark: false, width: 390.0, height: 560.0, scale: 1.0),
        (
          name: 'large-text',
          dark: true,
          width: 320.0,
          height: 920.0,
          scale: 2.0,
        ),
      ]) {
        tester.view.physicalSize = Size(variant.width, variant.height);
        final capture = GlobalKey();
        final theme = variant.dark ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              badgesProvider.overrideWithValue(
                variant.scale > 1
                    ? _previewBadges.take(3).toList()
                    : _previewBadges,
              ),
            ],
            child: MaterialApp(
              theme: theme.copyWith(
                textTheme: theme.textTheme.apply(
                  fontFamilyFallback: emojiPath == null
                      ? null
                      : const ['Preview Emoji'],
                ),
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(variant.scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: capture,
                child: Scaffold(
                  appBar: AppBar(title: const Text('My Profile')),
                  body: const SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: TrophyRoomCard(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final path = 'build/ui-review/trophies-${variant.name}.png';
          await File(path).parent.create(recursive: true);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

// Existing seeded badges, with representative progress for visual review.
final _previewBadges = [
  Badge(
    id: 'first_workout',
    category: 'workout',
    title: 'Welcome to the Iron',
    description: 'Log your first workout',
    iconEmoji: '\u{1F3CB}\uFE0F',
    requiredProgress: 1,
    currentProgress: 1,
    unlockedAt: DateTime(2026, 9, 19),
  ),
  Badge(
    id: 'workout_10',
    category: 'workout',
    title: 'Consistency Key',
    description: 'Log 10 workouts',
    iconEmoji: '\u{1F525}',
    requiredProgress: 10,
    currentProgress: 7,
  ),
  Badge(
    id: 'workout_50',
    category: 'workout',
    title: 'Iron Lifter',
    description: 'Log 50 workouts',
    iconEmoji: '\u{1F98D}',
    requiredProgress: 50,
  ),
  Badge(
    id: 'streak_3',
    category: 'streak',
    title: 'Momentum',
    description: 'Workout 3 days in a row',
    iconEmoji: '\u26A1',
    requiredProgress: 3,
    currentProgress: 3,
    unlockedAt: DateTime(2026, 9, 18),
  ),
  Badge(
    id: 'streak_7',
    category: 'streak',
    title: 'Unstoppable',
    description: 'Workout 7 days in a row',
    iconEmoji: '\u{1F525}',
    requiredProgress: 7,
    currentProgress: 3,
  ),
];
