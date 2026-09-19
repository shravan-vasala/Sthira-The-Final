import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/widgets/surface_card.dart';

Widget _host(Widget card, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(child: SizedBox(width: 300, child: card)),
      ),
    ),
  );
}

void main() {
  testWidgets('actionable cards expose a button and activate once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SurfaceCard(onTap: () => taps++, child: const Text('Open steps')),
        ),
      );

      final node = tester.getSemantics(find.text('Open steps'));
      expect(node.hasFlag(ui.SemanticsFlag.isButton), isTrue);
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      await tester.tap(find.text('Open steps'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keyboard focus supports Enter and Space exactly once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(SurfaceCard(onTap: () => taps++, child: const Text('Open steps'))),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(taps, 2);
  });

  testWidgets('cancelled presses do not open the card or leave it scaled', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(SurfaceCard(onTap: () => taps++, child: const Text('Open steps'))),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Open steps')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('nested actions do not also open the card', (tester) async {
    var cardTaps = 0;
    var editTaps = 0;
    await tester.pumpWidget(
      _host(
        SurfaceCard(
          onTap: () => cardTaps++,
          child: Row(
            children: [
              const Expanded(child: Text('Steps')),
              IconButton(
                tooltip: 'Edit steps',
                onPressed: () => editTaps++,
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Edit steps'));
    await tester.pumpAndSettle();
    expect(editTaps, 1);
    expect(cardTaps, 0);
    await tester.tap(find.text('Steps'));
    await tester.pumpAndSettle();
    expect(editTaps, 1);
    expect(cardTaps, 1);
  });

  testWidgets('outer gutters are not actionable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        SurfaceCard(
          margin: const EdgeInsets.all(20),
          onTap: () => taps++,
          child: const SizedBox(height: 60, child: Text('Open steps')),
        ),
      ),
    );

    final bounds = tester.getRect(find.byType(SurfaceCard));
    await tester.tapAt(Offset(bounds.left + 10, bounds.center.dy));
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + 10));
    await tester.pumpAndSettle();
    expect(taps, 0);
    await tester.tap(find.text('Open steps'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('reduced motion removes press scaling and ripple', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        SurfaceCard(onTap: () => taps++, child: const Text('Open steps')),
        reduceMotion: true,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Open steps')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).splashFactory,
      NoSplash.splashFactory,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('static cards have no button semantics or interactive surface', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(const SurfaceCard(child: Text('Daily summary'))),
      );

      final node = tester.getSemantics(find.text('Daily summary'));
      expect(node.hasFlag(ui.SemanticsFlag.isButton), isFalse);
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      expect(
        find.descendant(
          of: find.byType(SurfaceCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'making a bordered card actionable preserves its content geometry',
    (tester) async {
      Widget card(VoidCallback? onTap) => SurfaceCard(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 20, 24),
        border: Border.all(color: Colors.amber, width: 2),
        onTap: onTap,
        child: const Text('Daily summary'),
      );
      await tester.pumpWidget(_host(card(null)));
      final textBounds = tester.getRect(find.text('Daily summary'));
      final cardBounds = tester.getRect(find.byType(SurfaceCard));

      await tester.pumpWidget(_host(card(() {})));
      expect(tester.getRect(find.text('Daily summary')), textBounds);
      expect(tester.getRect(find.byType(SurfaceCard)), cardBounds);
    },
  );
}
