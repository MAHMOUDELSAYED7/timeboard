import 'package:timeboard/timeboard.dart';
import 'package:timeboard/src/calendar_widgets.dart';
import 'package:timeboard/src/time_grid.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TimeboardController _controller(TimeboardView view, {DateTime? now}) =>
    TimeboardController(
      view: view,
      now: () => now ?? TimeboardSampleData.today,
    );

Future<void> _pump(
  WidgetTester tester,
  TimeboardController controller,
  TimeboardTheme theme, {
  Size size = const Size(
    1672,
    1008,
  ), // 1920x1080 frame minus 248 sidebar/72 bar
  void Function(TimeboardEvent)? onEventTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Timeboard(
          controller: controller,
          theme: theme,
          events: TimeboardSampleData.events(),
          onEventTap: onEventTap,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final entry in {
    'light': TimeboardTheme.light,
    'dark': TimeboardTheme.dark,
  }.entries) {
    for (final view in TimeboardView.values) {
      testWidgets('${view.name} renders without errors (${entry.key})', (
        tester,
      ) async {
        await _pump(tester, _controller(view), entry.value);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('every view lays out at desktop window sizes without overflow', (
    tester,
  ) async {
    const sizes = [
      Size(2560, 1300),
      Size(1672, 1008),
      Size(1366, 768),
      Size(1100, 700),
      Size(960, 640),
      Size(800, 600),
      Size(640, 500),
    ];
    for (final size in sizes) {
      for (final theme in [TimeboardTheme.light, TimeboardTheme.dark]) {
        for (final view in TimeboardView.values) {
          await _pump(tester, _controller(view), theme, size: size);
          expect(
            tester.takeException(),
            isNull,
            reason: '${view.name} at $size',
          );
        }
      }
    }
  });

  testWidgets('toolbar keeps one row at desktop widths and two when narrow', (
    tester,
  ) async {
    final c = _controller(TimeboardView.month);
    await _pump(tester, c, TimeboardTheme.light, size: const Size(1366, 768));
    final wideTop = tester.getTopLeft(find.text('Month')).dy;
    final wideNew = tester.getTopLeft(find.text('New booking')).dy;
    // Same row: the switcher and the primary action line up.
    expect((wideTop - wideNew).abs(), lessThan(24));

    await _pump(tester, c, TimeboardTheme.light, size: const Size(800, 600));
    expect(tester.takeException(), isNull);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
  });

  testWidgets('a month day shows two bookings, then "+N more"', (tester) async {
    await _pump(tester, _controller(TimeboardView.month), TimeboardTheme.light);
    // 5 Oct has 4 bookings; 11 Oct and 14 Oct have 5: two chips each, the
    // rest collapsed.
    expect(find.text('+2 more'), findsOneWidget);
    expect(find.text('+3 more'), findsNWidgets(2)); // 11 Oct and today
    // Clients 1-3 sit on 5 Oct after Ahmed; only the first is drawn.
    expect(find.text('Client 1 · Kit'), findsOneWidget);
    expect(find.text('Client 2 · Kit'), findsNothing);
  });

  testWidgets('toolbar titles match the design', (tester) async {
    final c = _controller(TimeboardView.month);
    await _pump(tester, c, TimeboardTheme.light);
    expect(find.text('October 2026'), findsOneWidget);

    c.setView(TimeboardView.week);
    await tester.pump();
    expect(find.text('11–17 October 2026'), findsOneWidget);

    c.setView(TimeboardView.day);
    await tester.pump();
    expect(find.text('Wednesday, 14 October 2026'), findsOneWidget);

    c.setView(TimeboardView.agenda);
    await tester.pump();
    expect(find.text('Oct 14 – 20, 2026'), findsOneWidget);
  });

  testWidgets('next / previous step by the active view', (tester) async {
    final c = _controller(TimeboardView.month);
    await _pump(tester, c, TimeboardTheme.light);
    c.next();
    await tester.pump();
    expect(find.text('November 2026'), findsOneWidget);
    c.setView(TimeboardView.week);
    c.goToToday();
    c.previous();
    await tester.pump();
    expect(find.text('4–10 October 2026'), findsOneWidget);
  });

  testWidgets('tapping a month event reports it', (tester) async {
    TimeboardEvent? tapped;
    await _pump(
      tester,
      _controller(TimeboardView.month),
      TimeboardTheme.light,
      onEventTap: (e) => tapped = e,
    );
    await tester.tap(find.text('Mariam · Lighting package · Out'));
    expect(tapped?.id, 'm2');
  });

  testWidgets('agenda shows empty day, today marker and all statuses', (
    tester,
  ) async {
    await _pump(
      tester,
      _controller(TimeboardView.agenda),
      TimeboardTheme.light,
    );
    expect(find.text('No bookings'), findsNWidgets(3)); // 15, 18, 20 Oct
    expect(find.text('Booking #1048'), findsOneWidget);
    expect(find.text('10:00 AM – 2:00 PM'), findsOneWidget);
    expect(find.text('9:00 – 9:30 AM'), findsOneWidget);
    for (final s in ['Confirmed', 'Out', 'Returned', 'Draft', 'Conflict']) {
      expect(find.text(s), findsWidgets, reason: s);
    }
  });

  testWidgets('day view shows the all-day empty state and the 6 PM block', (
    tester,
  ) async {
    await _pump(tester, _controller(TimeboardView.day), TimeboardTheme.dark);
    expect(find.text('No all-day bookings'), findsOneWidget);
    expect(find.text('Tarek · Cinema lenses'), findsOneWidget);
    expect(find.text('Return · 6:00 PM'), findsOneWidget);
  });

  testWidgets('week shows whole-day bookings in an all-day strip', (
    tester,
  ) async {
    final c = _controller(TimeboardView.week);
    tester.view.physicalSize = const Size(1672, 1008);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Timeboard(
            controller: c,
            events: [
              for (var i = 0; i < 5; i++)
                TimeboardEvent(
                  id: 'd$i',
                  customer: 'Client $i',
                  allDay: true,
                  start: DateTime(2026, 10, 14),
                ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('ALL DAY'), findsOneWidget);
    expect(find.text('Client 0'), findsOneWidget);
    expect(find.text('+3 more'), findsOneWidget);
  });

  group('24-hour timeline', () {
    ScrollController gridController(WidgetTester tester) => tester
        .widget<SingleChildScrollView>(
          find
              .descendant(
                of: find.byType(TimeboardTimeGrid),
                matching: find.byType(SingleChildScrollView),
              )
              .first,
        )
        .controller!;

    for (final view in [TimeboardView.day, TimeboardView.week]) {
      testWidgets('${view.name} lists all 24 hours', (tester) async {
        await _pump(tester, _controller(view), TimeboardTheme.light);
        expect(find.text('12:00 AM'), findsOneWidget);
        expect(find.text('11:00 PM'), findsOneWidget);
        expect(find.text('12:00 PM'), findsWidgets);
      });

      testWidgets('${view.name} opens on the current hour', (tester) async {
        await _pump(
          tester,
          _controller(view, now: DateTime(2026, 10, 14, 10, 30)),
          TimeboardTheme.light,
        );
        expect(gridController(tester).offset, 10 * 64.0);
      });

      testWidgets('${view.name} can scroll up and down', (tester) async {
        await _pump(
          tester,
          _controller(view, now: DateTime(2026, 10, 14, 10, 30)),
          TimeboardTheme.light,
        );
        final c = gridController(tester);
        c.jumpTo(0);
        await tester.pump();
        expect(c.offset, 0);
        c.jumpTo(c.position.maxScrollExtent);
        await tester.pump();
        expect(c.offset, c.position.maxScrollExtent);
        expect(c.position.maxScrollExtent, greaterThan(0));
      });
    }

    testWidgets('late at night it settles on the last screen, not past it', (
      tester,
    ) async {
      await _pump(
        tester,
        _controller(TimeboardView.day, now: DateTime(2026, 10, 14, 23, 40)),
        TimeboardTheme.light,
      );
      await tester.pump();
      final c = gridController(tester);
      expect(c.offset, c.position.maxScrollExtent);
    });
  });

  testWidgets('the current-time dot moves on its own', (tester) async {
    var now = DateTime(2026, 10, 14, 10, 0);
    final c = TimeboardController(view: TimeboardView.day, now: () => now);
    await _pump(tester, c, TimeboardTheme.light);

    final line = find.byKey(const ValueKey('timeboard-now-dot'));
    expect(line, findsOneWidget);
    final before = tester.getTopLeft(line).dy;

    // Half an hour later, and no interaction: only the clock ticks.
    now = DateTime(2026, 10, 14, 10, 30);
    await tester.pump(const Duration(seconds: 31));

    expect(tester.getTopLeft(line).dy - before, closeTo(32, 0.5));
  });

  testWidgets('the current-time dot pulses and is green, with no red line', (
    tester,
  ) async {
    final c = TimeboardController(
      view: TimeboardView.day,
      now: () => DateTime(2026, 10, 14, 10, 0),
    );
    await _pump(tester, c, TimeboardTheme.light);

    Size dotSize() => tester.getSize(
      find
          .descendant(
            of: find.byKey(const ValueKey('timeboard-now-dot')),
            matching: find.byType(Container),
          )
          .last,
    );

    final start = dotSize();
    await tester.pump(const Duration(milliseconds: 550));
    expect(dotSize(), isNot(start)); // the dot is swelling or shrinking

    // The old red bar is gone.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == TimeboardTheme.light.error,
      ),
      findsNothing,
    );
  });

  testWidgets('weekend shading is optional', (tester) async {
    Future<void> pumpMonth(TimeboardOptions options) async {
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              controller: _controller(TimeboardView.month),
              options: options,
              events: const [],
            ),
          ),
        ),
      );
    }

    int shaded() => find
        .byWidgetPredicate(
          (w) => w is Material && w.color == TimeboardTheme.light.surfaceSubtle,
        )
        .evaluate()
        .length;

    await pumpMonth(const TimeboardOptions());
    final withWeekend = shaded();
    await pumpMonth(const TimeboardOptions(weekendDays: {}));
    expect(shaded(), lessThan(withWeekend));
  });

  group('current-time dot', () {
    final dot = find.byKey(const ValueKey('timeboard-now-dot'));
    TimeboardController at(TimeboardView v, DateTime now) =>
        TimeboardController(view: v, now: () => now);

    testWidgets('shows a tooltip on hover', (tester) async {
      await _pump(
        tester,
        at(TimeboardView.day, DateTime(2026, 10, 14, 10, 30)),
        TimeboardTheme.light,
      );
      expect(find.text('Current time · 10:30 AM'), findsNothing);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(dot));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Current time · 10:30 AM'), findsOneWidget);
    });

    testWidgets('shows a tooltip on tap', (tester) async {
      await _pump(
        tester,
        at(TimeboardView.week, DateTime(2026, 10, 14, 15, 5)),
        TimeboardTheme.dark,
      );
      await tester.tap(dot);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Current time · 3:05 PM'), findsOneWidget);
    });

    testWidgets('the tooltip text comes from the labels', (tester) async {
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              controller: at(TimeboardView.day, DateTime(2026, 10, 14, 10, 0)),
              labels: const TimeboardLabels(currentTime: 'الوقت الحالي'),
              events: const [],
            ),
          ),
        ),
      );
      await tester.tap(dot);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('الوقت الحالي'), findsOneWidget);
    });

    testWidgets(
      'sits in the hour gutter, clear of a booking at the same time',
      (tester) async {
        // Tarek's booking runs 18:00-19:30 on the 14th; it is 18:20 now.
        await _pump(
          tester,
          at(TimeboardView.week, DateTime(2026, 10, 14, 18, 20)),
          TimeboardTheme.light,
        );
        final booking = find.text('Tarek · Cinema lenses');
        expect(booking, findsOneWidget);

        final dotRect = tester.getRect(dot);
        final bookingLeft = tester.getTopLeft(booking).dx;

        // Entirely left of the booking: in the gutter, not over the column.
        expect(dotRect.right, lessThanOrEqualTo(bookingLeft));
        // And the booking has not been shifted to make room: it starts at the
        // column edge plus the usual 3px inset and 12px padding.
        await tester.pump(const Duration(seconds: 31));
        expect(tester.getTopLeft(booking).dx, bookingLeft);
      },
    );

    testWidgets('is not drawn when today is not on screen', (tester) async {
      final c = at(TimeboardView.day, DateTime(2026, 10, 14, 10, 0));
      await _pump(tester, c, TimeboardTheme.light);
      expect(dot, findsOneWidget);
      c.setFocusedDate(DateTime(2026, 10, 20));
      await tester.pump();
      expect(dot, findsNothing);
    });
  });

  group('date navigation', () {
    Finder arrow(String name) =>
        find.byWidgetPredicate((w) => w is TimeboardIcon && w.name == name);

    for (final view in TimeboardView.values) {
      testWidgets('the arrows stay put as the title changes (${view.name})', (
        tester,
      ) async {
        final c = _controller(view);
        await _pump(tester, c, TimeboardTheme.light);

        final left = tester.getTopLeft(arrow('chevron_left')).dx;
        final right = tester.getTopLeft(arrow('chevron_right')).dx;

        // Every month, and each step through them, changes the title text.
        final titles = <String>{};
        for (var m = 1; m <= 14; m++) {
          c.setFocusedDate(DateTime(2026, m, m == 3 ? 1 : 28));
          await tester.pump();
          titles.add(
            (tester.widgetList<Text>(
              find.byType(Text),
            )).map((t) => t.data).join('|'),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getTopLeft(arrow('chevron_left')).dx,
            left,
            reason: '${view.name} month $m',
          );
          expect(
            tester.getTopLeft(arrow('chevron_right')).dx,
            right,
            reason: '${view.name} month $m',
          );
        }
        expect(titles.length, greaterThan(1)); // the title did change
      });
    }

    testWidgets('the title is centred between the arrows', (tester) async {
      final c = _controller(TimeboardView.month);
      await _pump(tester, c, TimeboardTheme.light);
      c.setFocusedDate(DateTime(2026, 5, 1)); // "May 2026": short
      await tester.pump();
      final title = tester.getCenter(find.text('May 2026')).dx;
      final mid =
          (tester.getTopRight(arrow('chevron_left')).dx +
              tester.getTopLeft(arrow('chevron_right')).dx) /
          2;
      expect(title, closeTo(mid, 12));
    });
  });

  group('week all-day strip', () {
    Future<DateTime?> pumpWeek(WidgetTester tester, int count) async {
      DateTime? tapped;
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              controller: _controller(TimeboardView.week),
              onDayTap: (d) => tapped = d,
              events: [
                for (var i = 0; i < count; i++)
                  TimeboardEvent(
                    id: 'e$i',
                    customer: 'Client $i',
                    allDay: true,
                    start: DateTime(2026, 10, 14),
                  ),
              ],
            ),
          ),
        ),
      );
      return tapped;
    }

    testWidgets('two bookings fit without a "more" row', (tester) async {
      await pumpWeek(tester, 2);
      expect(find.text('Client 0'), findsOneWidget);
      expect(find.text('Client 1'), findsOneWidget);
      expect(find.textContaining('more'), findsNothing);
    });

    testWidgets('three show two and "+1 more"', (tester) async {
      await pumpWeek(tester, 3);
      expect(find.text('Client 0'), findsOneWidget);
      expect(find.text('Client 1'), findsOneWidget);
      expect(find.text('Client 2'), findsNothing);
      expect(find.text('+1 more'), findsOneWidget);
    });

    testWidgets('"+N more" opens that day', (tester) async {
      DateTime? tapped;
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              controller: _controller(TimeboardView.week),
              onDayTap: (d) => tapped = d,
              events: [
                for (var i = 0; i < 4; i++)
                  TimeboardEvent(
                    id: 'e$i',
                    customer: 'Client $i',
                    allDay: true,
                    start: DateTime(2026, 10, 14),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('+2 more'));
      expect(tapped, DateTime(2026, 10, 14));
    });
  });

  group('date picker from the toolbar title', () {
    Future<void> settle(WidgetTester tester) async {
      // Not pumpAndSettle: the current-time dot animates forever.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('tapping the date opens it on the focused day', (tester) async {
      final c = _controller(TimeboardView.month);
      await _pump(tester, c, TimeboardTheme.light);
      expect(find.byType(TimeboardDatePicker), findsNothing);

      await tester.tap(find.text('October 2026'));
      await settle(tester);
      expect(find.byType(TimeboardDatePicker), findsOneWidget);
    });

    testWidgets('picking a day moves the calendar there and closes it', (
      tester,
    ) async {
      final c = _controller(TimeboardView.month);
      await _pump(tester, c, TimeboardTheme.light);

      await tester.tap(find.text('October 2026'));
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(TimeboardDatePicker),
          matching: find.text('21'),
        ),
      );
      await settle(tester);

      expect(find.byType(TimeboardDatePicker), findsNothing);
      expect(c.focusedDate, DateTime(2026, 10, 21));
    });

    testWidgets('in the week view the week of the picked day is shown', (
      tester,
    ) async {
      final c = _controller(TimeboardView.week);
      await _pump(tester, c, TimeboardTheme.dark);

      await tester.tap(find.text('11–17 October 2026'));
      await settle(tester);
      // 29 Sep also sits in the grid's first row; the second "29" is October.
      await tester.tap(
        find
            .descendant(
              of: find.byType(TimeboardDatePicker),
              matching: find.text('29'),
            )
            .last,
      );
      await settle(tester);

      expect(c.focusedDate, DateTime(2026, 10, 29));
      expect(find.text('25–31 October 2026'), findsOneWidget);
      expect(c.view, TimeboardView.week); // the view is left alone
    });

    testWidgets('can be switched off', (tester) async {
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              controller: _controller(TimeboardView.month),
              enableDatePicker: false,
              events: const [],
            ),
          ),
        ),
      );
      await tester.tap(find.text('October 2026'));
      await settle(tester);
      expect(find.byType(TimeboardDatePicker), findsNothing);
    });

    testWidgets('has no reset or cancel button in the calendar', (
      tester,
    ) async {
      final c = _controller(TimeboardView.month);
      await _pump(tester, c, TimeboardTheme.light);
      await tester.tap(find.text('October 2026'));
      await settle(tester);
      expect(find.byType(TimeboardDatePicker), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('dismissing it leaves the date alone', (tester) async {
      final c = _controller(TimeboardView.month);
      await _pump(tester, c, TimeboardTheme.light);
      await tester.tap(find.text('October 2026'));
      await settle(tester);
      await tester.tapAt(const Offset(5, 5)); // the barrier
      await settle(tester);
      expect(find.byType(TimeboardDatePicker), findsNothing);
      expect(c.focusedDate, DateTime(2026, 10, 14));
    });
  });

  group('today in the month', () {
    Material chipFor(WidgetTester tester, String text) =>
        tester.widget<Material>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Material))
              .first,
        );

    for (final entry in {
      'light': TimeboardTheme.light,
      'dark': TimeboardTheme.dark,
    }.entries) {
      testWidgets('its bookings have a border, others do not (${entry.key})', (
        tester,
      ) async {
        await _pump(tester, _controller(TimeboardView.month), entry.value);

        // 14 Oct is today; its first two bookings are drawn, earliest first.
        final today =
            chipFor(
                  tester,
                  'Nour Khaled · Rode Wireless Pro ×2, Sennheiser MKH 416',
                ).shape
                as RoundedRectangleBorder;
        expect(today.side.style, BorderStyle.solid);
        expect(today.side.color.a, greaterThan(0));
        expect(today.side.color.a, lessThan(1)); // a hairline, not a frame

        // 8 Oct is not.
        final other =
            chipFor(tester, 'Mariam · Lighting package · Out').shape
                as RoundedRectangleBorder;
        expect(other.side.style, BorderStyle.none);
      });
    }

    testWidgets('the border is the booking\'s own text colour', (tester) async {
      await _pump(
        tester,
        _controller(TimeboardView.month),
        TimeboardTheme.dark,
      );
      final shape =
          chipFor(
                tester,
                'Nour Khaled · Rode Wireless Pro ×2, Sennheiser MKH 416',
              ).shape
              as RoundedRectangleBorder;
      final text = TimeboardTheme.dark.returned.text;
      expect(
        shape.side.color.toARGB32() & 0xFFFFFF,
        text.toARGB32() & 0xFFFFFF,
      );
    });

    testWidgets('the today wash is the design\'s own colour', (tester) async {
      // Bookings stand out from it by their border, not by changing it.
      expect(TimeboardTheme.dark.surfaceToday.toARGB32(), 0xFF122B37);
      expect(TimeboardTheme.light.surfaceToday.toARGB32(), 0xFFF2FBFF);
    });
  });
}
