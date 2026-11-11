import 'package:timeboard/timeboard.dart';
import 'package:timeboard_example/main.dart';
import 'package:timeboard_example/variants/playground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('every variant renders without errors', (tester) async {
    await open(tester);
    for (final name in [
      'Ops dashboard',
      'Minimal month',
      'Planner timeline',
      'Playground',
    ]) {
      await tester.tap(find.text(name));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: name);
    }
  });

  testWidgets('ops dashboard switches through all four views', (tester) async {
    await open(tester);
    for (final v in ['Week', 'Day', 'Agenda', 'Month']) {
      await tester.tap(find.text(v).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: v);
    }
  });

  testWidgets('minimal month offers one view and no action buttons', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Minimal month'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('New booking'), findsNothing);
    expect(find.text('Filters'), findsNothing);
    expect(find.text('Week'), findsNothing);
  });

  testWidgets('planner timeline is week and day only, in Arabic', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Planner timeline'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('أسبوع'), findsOneWidget);
    expect(find.text('يوم'), findsOneWidget);
    expect(find.text('Month'), findsNothing);
  });

  testWidgets('playground controls change the calendar live', (tester) async {
    await open(tester);
    await tester.tap(find.text('Playground'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('New booking'), findsWidgets);
    await tester.tap(find.text('Toolbar & views'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'New booking');
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(toggle);
    await tester.pump();
    final calendar = tester.widget<Timeboard>(
      find.descendant(
        of: find.byType(Playground),
        matching: find.byType(Timeboard),
      ),
    );
    expect(calendar.options.showNewBooking, isFalse);
  });

  group('phones and tablets', () {
    const devices = {
      'Android phone': Size(360, 800),
      'iPhone': Size(390, 844),
      'iPad': Size(820, 1180),
    };
    for (final d in devices.entries) {
      testWidgets('${d.key}: every variant renders without errors', (
        tester,
      ) async {
        tester.view.physicalSize = d.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const DemoApp());
        await tester.pump(const Duration(milliseconds: 300));
        final phone = d.value.width < 700;
        for (final name in [
          'Ops dashboard',
          'Minimal month',
          'Planner timeline',
          'Playground',
        ]) {
          final tab = phone
              ? find.descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text(name),
                )
              : find.text(name);
          await tester.tap(tab);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: '${d.key} · $name');
        }
      });
    }

    testWidgets('phone playground opens its parameters in a drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DemoApp());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Playground'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Parameters'));
      await tester.pumpAndSettle();
      expect(find.text('Parameters'), findsWidgets);
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
