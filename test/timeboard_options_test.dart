import 'package:timeboard/timeboard.dart';
import 'support/sample_data.dart';
import 'package:timeboard/src/event_index.dart';
import 'package:timeboard/src/time_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = TimeboardSampleData.today; // 14 Oct 2026

TimeboardController _controller(TimeboardView v) =>
    TimeboardController(view: v, now: () => _today);

Future<void> _pump(
  WidgetTester tester, {
  TimeboardController? controller,
  TimeboardOptions options = const TimeboardOptions(),
  TimeboardLabels labels = const TimeboardLabels(),
  TimeboardTheme? theme,
  List<TimeboardEvent>? events,
  TimeboardEventBuilder? eventBuilder,
  TimeboardEventColors? eventColors,
  ValueChanged<TimeboardView>? onViewChanged,
  ValueChanged<DateTime>? onDateChanged,
}) async {
  tester.view.physicalSize = const Size(1672, 1008);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Timeboard(
          controller: controller ?? _controller(TimeboardView.month),
          theme: theme ?? TimeboardTheme.light,
          events: events ?? TimeboardSampleData.events(),
          options: options,
          labels: labels,
          eventBuilder: eventBuilder,
          eventColors: eventColors,
          onViewChanged: onViewChanged,
          onDateChanged: onDateChanged,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TimeboardEventIndex', () {
    TimeboardEvent ev(String id, DateTime s, [DateTime? e]) =>
        TimeboardEvent(id: id, customer: id, start: s, end: e);

    test('lists a multi-day event on every day it touches, earliest first', () {
      final index = TimeboardEventIndex([
        ev('b', DateTime(2026, 10, 5, 12), DateTime(2026, 10, 7, 9)),
        ev('a', DateTime(2026, 10, 5, 8), DateTime(2026, 10, 5, 9)),
      ]);
      expect(index.on(DateTime(2026, 10, 5)).map((e) => e.id), ['a', 'b']);
      expect(index.on(DateTime(2026, 10, 6)).map((e) => e.id), ['b']);
      expect(index.on(DateTime(2026, 10, 7)).map((e) => e.id), ['b']);
      expect(index.on(DateTime(2026, 10, 8)), isEmpty);
    });

    test('an event ending at midnight does not spill onto the next day', () {
      final index = TimeboardEventIndex([
        ev('x', DateTime(2026, 10, 5, 22), DateTime(2026, 10, 6)),
      ]);
      expect(index.on(DateTime(2026, 10, 6)), isEmpty);
    });

    test('ties on start time are ordered by id, not by chance', () {
      final t = DateTime(2026, 10, 5, 9);
      final index = TimeboardEventIndex([ev('c', t), ev('a', t), ev('b', t)]);
      expect(index.on(t).map((e) => e.id), ['a', 'b', 'c']);
    });

    test('a runaway end date cannot allocate millions of days', () {
      final index = TimeboardEventIndex([
        ev('x', DateTime(2026, 1, 1), DateTime(9999, 1, 1)),
      ]);
      expect(index.on(DateTime(2026, 1, 1)), hasLength(1));
      expect(index.on(DateTime(2030, 1, 1)), isEmpty);
    });

    test('is reused for the same list and rebuilt for another', () {
      final list = [ev('a', DateTime(2026, 10, 5))];
      final index = TimeboardEventIndex(list);
      expect(index.isFor(list), isTrue);
      expect(index.isFor([...list]), isFalse);
      list.add(ev('b', DateTime(2026, 10, 5)));
      expect(index.isFor(list), isFalse);
    });
  });

  group('value equality', () {
    test('options and themes compare by value', () {
      expect(const TimeboardOptions(), const TimeboardOptions());
      expect(
        const TimeboardOptions().hashCode,
        const TimeboardOptions().hashCode,
      );
      expect(
        const TimeboardOptions(),
        isNot(const TimeboardOptions(hourHeight: 80)),
      );
      expect(TimeboardTheme.light.copyWith(), TimeboardTheme.light);
      expect(
        TimeboardTheme.light.copyWith(panelRadius: 4),
        isNot(TimeboardTheme.light),
      );
    });

    test('fromSeed makes the brand the action colour', () {
      const brand = Color(0xFFD81B60);
      final light = TimeboardTheme.fromSeed(brand);
      final dark = TimeboardTheme.fromSeed(brand, brightness: Brightness.dark);
      expect(light.actionPrimary, brand);
      expect(dark.actionPrimary, brand);
      expect(dark.surfaceCanvas, TimeboardTheme.dark.surfaceCanvas);
      expect(light.contentBrand, isNot(dark.contentBrand));
    });

    test('options reject impossible values', () {
      expect(() => TimeboardOptions(dayEndHour: 25), throwsAssertionError);
      expect(() => TimeboardOptions(hourHeight: 0), throwsAssertionError);
      expect(() => TimeboardOptions(agendaDays: 0), throwsAssertionError);
    });
  });

  group('options', () {
    testWidgets('views limits the switcher', (tester) async {
      await _pump(
        tester,
        options: const TimeboardOptions(
          views: [TimeboardView.month, TimeboardView.agenda],
        ),
      );
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.text('Week'), findsNothing);
      expect(find.text('Day'), findsNothing);
    });

    testWidgets('showToolbar: false leaves only the panel', (tester) async {
      await _pump(tester, options: const TimeboardOptions(showToolbar: false));
      expect(find.text('Today'), findsNothing);
      expect(find.text('New booking'), findsNothing);
      expect(find.text('Sun'), findsNothing); // labels are upper-case
      expect(find.text('SUN'), findsOneWidget);
    });

    testWidgets('individual toolbar parts can be hidden', (tester) async {
      await _pump(
        tester,
        options: const TimeboardOptions(
          showTodayButton: false,
          showFilters: false,
          showNewBooking: false,
          showViewSwitcher: false,
        ),
      );
      expect(find.text('Today'), findsNothing);
      expect(find.text('Month'), findsNothing);
      expect(find.text('New booking'), findsNothing);
      expect(find.byTooltip('Filters'), findsNothing);
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('maxChipsPerDay sets where "+N more" starts', (tester) async {
      // 5 Oct 2026 has four bookings.
      await _pump(tester);
      expect(find.text('+2 more'), findsOneWidget);
      await _pump(tester, options: const TimeboardOptions(maxChipsPerDay: 1));
      expect(find.text('+3 more'), findsOneWidget);
      // Tall rows have room for four chips, so nothing is hidden.
      await _pump(
        tester,
        options: const TimeboardOptions(
          maxChipsPerDay: 4,
          minMonthRowHeight: 250,
        ),
      );
      expect(find.text('+2 more'), findsNothing);
      expect(find.text('+3 more'), findsNothing);
    });

    testWidgets('"+N more" is never clipped away by a high maxChipsPerDay', (
      tester,
    ) async {
      // Five chips cannot fit a 136px row: the cell shows what fits and
      // keeps the "+N more" row visible instead of cutting it off.
      await _pump(tester, options: const TimeboardOptions(maxChipsPerDay: 5));
      final more = find.textContaining('more');
      expect(more, findsWidgets);
      for (final e in more.evaluate()) {
        final box = tester.getRect(find.byWidget(e.widget));
        final cell = tester.getRect(
          find
              .ancestor(
                of: find.byWidget(e.widget),
                matching: find.byType(InkWell),
              )
              .last,
        );
        expect(box.bottom, lessThanOrEqualTo(cell.bottom + 0.5));
      }
    });

    testWidgets('hourHeight scales the timeline', (tester) async {
      Future<double> gridHeight(double hourHeight) async {
        await _pump(
          tester,
          controller: _controller(TimeboardView.day),
          options: TimeboardOptions(hourHeight: hourHeight),
        );
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(TimeboardTimeGrid),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        return scroll.position.maxScrollExtent +
            scroll.position.viewportDimension;
      }

      expect(await gridHeight(48), closeTo(48 * 24, 0.5));
      expect(await gridHeight(96), closeTo(96 * 24, 0.5));
    });

    testWidgets('dayStartHour and dayEndHour crop the timeline', (
      tester,
    ) async {
      await _pump(
        tester,
        controller: _controller(TimeboardView.day),
        options: const TimeboardOptions(dayStartHour: 8, dayEndHour: 12),
      );
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
      expect(find.text('12:00 PM'), findsNothing);
      expect(find.text('7:00 AM'), findsNothing);
    });

    testWidgets('agendaDays changes how many days are listed', (tester) async {
      await _pump(
        tester,
        controller: _controller(TimeboardView.agenda),
        options: const TimeboardOptions(agendaDays: 3),
      );
      // 14, 15, 16 Oct: the 17th (Dina Fathy) is out of range.
      expect(find.text('Dina Fathy'), findsNothing);
      expect(find.text('Layla Mostafa'), findsOneWidget);
      expect(find.text('Oct 14 – 16, 2026'), findsOneWidget);
    });

    testWidgets('animateNowIndicator: false leaves nothing animating', (
      tester,
    ) async {
      await _pump(
        tester,
        controller: TimeboardController(
          view: TimeboardView.day,
          now: () => DateTime(2026, 10, 14, 10, 30),
        ),
        options: const TimeboardOptions(animateNowIndicator: false),
      );
      expect(find.byKey(const ValueKey('timeboard-now-dot')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('showNowIndicator: false removes the dot', (tester) async {
      await _pump(
        tester,
        controller: TimeboardController(
          view: TimeboardView.day,
          now: () => DateTime(2026, 10, 14, 10, 30),
        ),
        options: const TimeboardOptions(showNowIndicator: false),
      );
      expect(find.byKey(const ValueKey('timeboard-now-dot')), findsNothing);
    });
  });

  group('look', () {
    testWidgets('use24Hour shows 24-hour times', (tester) async {
      await _pump(
        tester,
        controller: _controller(TimeboardView.day),
        labels: const TimeboardLabels(use24Hour: true),
      );
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('9:00 AM'), findsNothing);
    });

    testWidgets('eventBuilder replaces the month chip', (tester) async {
      await _pump(
        tester,
        eventBuilder: (context, e, slot) => slot == TimeboardEventSlot.monthChip
            ? Text('custom ${e.id}')
            : null,
      );
      expect(find.text('custom m2'), findsOneWidget);
    });

    testWidgets('eventBuilder returning null keeps the default', (
      tester,
    ) async {
      await _pump(tester, eventBuilder: (context, e, slot) => null);
      expect(find.text('Mariam · Lighting package · Out'), findsOneWidget);
    });

    testWidgets('eventColors paints a booking in the host colours', (
      tester,
    ) async {
      const pink = TimeboardStatusColors(
        fill: Color(0xFFFF00FF),
        text: Colors.black,
      );
      await _pump(tester, eventColors: (e, theme) => pink);
      final chip = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Mariam · Lighting package · Out'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(chip.color, pink.fill);
    });

    testWidgets('panelRadius follows the theme', (tester) async {
      await _pump(tester, theme: TimeboardTheme.light.copyWith(panelRadius: 2));
      final panel = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.foregroundDecoration is BoxDecoration)
          .first;
      final deco = panel.foregroundDecoration! as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.circular(2));
    });
  });

  group('callbacks', () {
    testWidgets('onViewChanged and onDateChanged fire once per change', (
      tester,
    ) async {
      final views = <TimeboardView>[];
      final dates = <DateTime>[];
      final c = _controller(TimeboardView.month);
      await _pump(
        tester,
        controller: c,
        onViewChanged: views.add,
        onDateChanged: dates.add,
      );

      await tester.tap(find.text('Week'));
      await tester.pump();
      expect(views, [TimeboardView.week]);
      expect(dates, isEmpty);

      c.next();
      await tester.pump();
      expect(dates, [DateTime(2026, 10, 21)]);

      // Setting the same day again is not a change.
      c.setFocusedDate(DateTime(2026, 10, 21, 15));
      await tester.pump();
      expect(dates, hasLength(1));
    });

    testWidgets('own controller honours initialView and firstWeekday', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Timeboard(
              events: const [],
              initialView: TimeboardView.agenda,
              initialDate: DateTime(2026, 10, 14),
              firstWeekday: DateTime.monday,
            ),
          ),
        ),
      );
      expect(find.text('Oct 14 – 20, 2026'), findsOneWidget);
    });

    testWidgets('swapping the controller moves the listener', (tester) async {
      final a = _controller(TimeboardView.month);
      final b = _controller(TimeboardView.month);
      final dates = <DateTime>[];
      Widget app(TimeboardController c) => MaterialApp(
        home: Scaffold(
          body: Timeboard(
            controller: c,
            events: const [],
            onDateChanged: dates.add,
          ),
        ),
      );
      tester.view.physicalSize = const Size(1672, 1008);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(a));
      await tester.pumpWidget(app(b));
      a.next(); // detached: must not report
      b.next();
      await tester.pump();
      expect(dates, [DateTime(2026, 11, 1)]);
    });
  });
}
