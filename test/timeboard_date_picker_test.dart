import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 14);

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<DateTime> onSelected,
  DateTime? initial,
  DateTime? first,
  DateTime? last,
  bool confirm = false,
  bool showReset = false,
  VoidCallback? onCancel,
  Brightness brightness = Brightness.light,
  Size size = const Size(900, 700),
  double width = 520,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(
          child: TimeboardDatePicker(
            initialDate: initial ?? _today,
            firstDate: first,
            lastDate: last,
            today: _today,
            showConfirmButton: confirm,
            showResetButton: showReset,
            onCancel: onCancel,
            width: width,
            onDateSelected: onSelected,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the month, the weekday heads and the year column', (
    tester,
  ) async {
    await _pump(tester, onSelected: (_) {});

    expect(find.text('October 2026'), findsOneWidget);
    for (final d in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']) {
      expect(find.text(d), findsOneWidget, reason: d);
    }
    // Sunday first, so a Sunday-first week; the order is left to right.
    expect(
      tester.getTopLeft(find.text('Su')).dx,
      lessThan(tester.getTopLeft(find.text('Sa')).dx),
    );
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);
  });

  testWidgets('first weekday is a parameter', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeboardDatePicker(
            initialDate: _today,
            today: _today,
            firstWeekday: DateTime.saturday,
            onDateSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Sa')).dx,
      lessThan(tester.getTopLeft(find.text('Su')).dx),
    );
    expect(
      tester.getTopLeft(find.text('Fr')).dx,
      greaterThan(tester.getTopLeft(find.text('Th')).dx),
    );
  });

  group('selecting', () {
    testWidgets('a day completes the pick straight away by default', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(tester, onSelected: (d) => picked = d);

      expect(find.text('Confirm'), findsNothing);
      await tester.tap(find.text('20'));
      expect(picked, DateTime(2026, 10, 20));
    });

    testWidgets('with the confirm button the day is only marked until then', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(tester, onSelected: (d) => picked = d, confirm: true);

      await tester.tap(find.text('20'));
      await tester.pump();
      expect(picked, isNull);

      // Still free to change its mind.
      await tester.tap(find.text('22'));
      await tester.pump();
      expect(picked, isNull);

      await tester.tap(find.text('Confirm'));
      expect(picked, DateTime(2026, 10, 22));
    });

    testWidgets(
      'confirming without touching anything returns the initial day',
      (tester) async {
        DateTime? picked;
        await _pump(tester, onSelected: (d) => picked = d, confirm: true);
        await tester.tap(find.text('Confirm'));
        expect(picked, DateTime(2026, 10, 14));
      },
    );

    testWidgets('a day from the next month selects it and opens that month', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(tester, onSelected: (d) => picked = d);

      // 31 Oct is a Saturday; the grid ends 7 Nov. "7" appears once (Oct 7 is
      // in the month too), so take the last.
      await tester.tap(find.text('7').last);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 11, 7));
      expect(find.text('November 2026'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('the arrows step a month', (tester) async {
      await _pump(tester, onSelected: (_) {});
      Finder arrow(String name) => find.byWidgetPredicate(
        (w) =>
            w.runtimeType.toString() == 'TimeboardIcon' &&
            (w as dynamic).name == name,
      );

      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.tap(arrow('chevron_left'));
      await tester.tap(arrow('chevron_left'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('tapping a year jumps to the same month in it', (tester) async {
      await _pump(tester, onSelected: (_) {});
      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();
      expect(find.text('October 2024'), findsOneWidget);
    });

    testWidgets('the year column follows the month across a year boundary', (
      tester,
    ) async {
      await _pump(tester, initial: DateTime(2026, 12, 5), onSelected: (_) {});
      Finder arrow(String name) => find.byWidgetPredicate(
        (w) =>
            w.runtimeType.toString() == 'TimeboardIcon' &&
            (w as dynamic).name == name,
      );
      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      expect(find.text('January 2027'), findsOneWidget);
      expect(find.text('2027'), findsOneWidget);
    });

    testWidgets('the year list is not a fixed handful of years', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(tester, onSelected: (d) => picked = d);
      // Far from the 2022-2028 the original hard-coded.
      await tester.drag(find.text('2026'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('2018'), findsOneWidget);
      expect(picked, isNull);
    });
  });

  group('range', () {
    testWidgets('days outside it cannot be picked', (tester) async {
      DateTime? picked;
      await _pump(
        tester,
        first: DateTime(2026, 10, 10),
        last: DateTime(2026, 10, 20),
        onSelected: (d) => picked = d,
      );
      await tester.tap(find.text('5').first); // 5 Oct, before the range
      expect(picked, isNull);
      await tester.tap(find.text('25')); // after it
      expect(picked, isNull);
      await tester.tap(find.text('15'));
      expect(picked, DateTime(2026, 10, 15));
    });

    testWidgets('the arrows stop at the first and last month', (tester) async {
      await _pump(
        tester,
        first: DateTime(2026, 10, 10),
        last: DateTime(2026, 11, 20),
        onSelected: (_) {},
      );
      Finder arrow(String name) => find.byWidgetPredicate(
        (w) =>
            w.runtimeType.toString() == 'TimeboardIcon' &&
            (w as dynamic).name == name,
      );

      await tester.tap(arrow('chevron_left'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('an initial date outside the range is clamped into it', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(
        tester,
        initial: DateTime(2030, 1, 1),
        first: DateTime(2026, 1, 1),
        last: DateTime(2026, 12, 31),
        confirm: true,
        onSelected: (d) => picked = d,
      );
      await tester.tap(find.text('Confirm'));
      expect(picked, DateTime(2026, 12, 31));
    });
  });

  testWidgets('lays out in light and dark, wide and narrow', (tester) async {
    for (final b in Brightness.values) {
      for (final size in const [Size(900, 700), Size(380, 700)]) {
        await _pump(
          tester,
          onSelected: (_) {},
          brightness: b,
          size: size,
          confirm: true,
        );
        expect(tester.takeException(), isNull, reason: '$b $size');
      }
    }
  });

  testWidgets('showTimeboardDatePicker resolves to the picked day', (
    tester,
  ) async {
    DateTime? result;
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showTimeboardDatePicker(
                context,
                initialDate: _today,
                today: _today,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeboardDatePicker), findsOneWidget);

    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 10, 21));
    expect(find.byType(TimeboardDatePicker), findsNothing);
  });

  group('reset and cancel', () {
    Finder arrow(String name) => find.byWidgetPredicate(
      (w) =>
          w.runtimeType.toString() == 'TimeboardIcon' &&
          (w as dynamic).name == name,
    );

    testWidgets('neither is there by default', (tester) async {
      await _pump(tester, onSelected: (_) {});
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('each one is there only when asked for', (tester) async {
      await _pump(tester, onSelected: (_) {}, showReset: true);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byTooltip('Reset'), findsOneWidget);

      await _pump(tester, onSelected: (_) {}, onCancel: () {});
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('they sit at the top, above the month', (tester) async {
      await _pump(tester, onSelected: (_) {}, showReset: true, onCancel: () {});
      final reset = tester.getRect(find.byIcon(Icons.refresh_rounded));
      final cancel = tester.getRect(find.byIcon(Icons.close_rounded));
      final title = tester.getRect(find.text('October 2026'));
      expect(reset.bottom, lessThan(title.top));
      expect(cancel.bottom, lessThan(title.top));
      // Reset first, cancel last.
      expect(reset.left, lessThan(cancel.left));
    });

    testWidgets('reset puts the day and the month back, and confirms nothing', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(
        tester,
        onSelected: (d) => picked = d,
        confirm: true,
        showReset: true,
      );

      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9').first);
      await tester.pump();
      expect(find.text('November 2026'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(picked, isNull);

      await tester.tap(find.text('Confirm'));
      expect(picked, DateTime(2026, 10, 14)); // the initial day again
    });

    testWidgets('reset without a confirm button does not pick anything', (
      tester,
    ) async {
      DateTime? picked;
      await _pump(tester, onSelected: (d) => picked = d, showReset: true);
      await tester.tap(arrow('chevron_right'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(picked, isNull);
    });

    testWidgets('cancel calls onCancel and picks nothing', (tester) async {
      var cancelled = 0;
      DateTime? picked;
      await _pump(
        tester,
        onSelected: (d) => picked = d,
        onCancel: () => cancelled++,
      );
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(cancelled, 1);
      expect(picked, isNull);
    });

    testWidgets('in the dialog, cancel closes it with no result', (
      tester,
    ) async {
      DateTime? result = DateTime(1999);
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showTimeboardDatePicker(
                  context,
                  initialDate: _today,
                  showCancelButton: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TimeboardDatePicker), findsNothing);
      expect(result, isNull);
    });

    testWidgets('a long, narrow, dark layout still fits with the top bar', (
      tester,
    ) async {
      await _pump(
        tester,
        onSelected: (_) {},
        showReset: true,
        onCancel: () {},
        confirm: true,
        brightness: Brightness.dark,
        size: const Size(380, 700),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('showTimeboardDatePicker has neither button unless asked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showTimeboardDatePicker(context, initialDate: _today),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeboardDatePicker), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
