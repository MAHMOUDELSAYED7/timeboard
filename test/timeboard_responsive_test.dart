import 'package:timeboard/timeboard.dart';
import 'support/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical sizes of real devices (portrait and landscape).
const _devices = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'Android 360x800': Size(360, 800),
  'iPhone 390x844': Size(390, 844),
  'iPhone Pro Max 430x932': Size(430, 932),
  'phone landscape 844x390': Size(844, 390),
  'small tablet 600x960': Size(600, 960),
  'iPad mini 744x1133': Size(744, 1133),
  'iPad 820x1180': Size(820, 1180),
  'iPad landscape 1180x820': Size(1180, 820),
  'tablet landscape 1280x800': Size(1280, 800),
};

final _today = TimeboardSampleData.today;

Future<void> _pump(
  WidgetTester tester,
  Size size,
  TimeboardView view, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  TimeboardOptions options = const TimeboardOptions(),
  TimeboardController? controller,
  ValueChanged<TimeboardEvent>? onEventTap,
  ValueChanged<DateTime>? onDayTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Timeboard(
          controller:
              controller ?? TimeboardController(view: view, now: () => _today),
          events: TimeboardSampleData.events(),
          options: options,
          onEventTap: onEventTap,
          onDayTap: onDayTap,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  pickerOnPhones();
  group('every view fits every device without overflow', () {
    for (final device in _devices.entries) {
      for (final view in TimeboardView.values) {
        for (final scale in [1.0, 1.5]) {
          testWidgets('${device.key} · ${view.name} · text x$scale', (
            tester,
          ) async {
            for (final b in Brightness.values) {
              await _pump(
                tester,
                device.value,
                view,
                brightness: b,
                textScale: scale,
              );
              expect(tester.takeException(), isNull);
            }
          });
        }
      }
    }
  });

  group('phone layout', () {
    const phone = Size(390, 844);

    testWidgets('month shows dots and a list for the selected day', (
      tester,
    ) async {
      await _pump(tester, phone, TimeboardView.month);
      // Chips are gone: the long chip label is not drawn in the grid.
      expect(find.text('Ahmed · Sony FX3 · Pickup 10:00'), findsNothing);
      // The selected day (14 Oct) lists its bookings below the grid.
      await tester.scrollUntilVisible(
        find.text('Ahmed Hassan'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ahmed Hassan'), findsOneWidget);
    });

    testWidgets('tapping a day selects it; tapping it again opens it', (
      tester,
    ) async {
      final tapped = <DateTime>[];
      final c = TimeboardController(
        view: TimeboardView.month,
        now: () => _today,
      );
      await _pump(
        tester,
        phone,
        TimeboardView.month,
        controller: c,
        onDayTap: tapped.add,
      );

      await tester.tap(find.text('16').first);
      await tester.pump();
      expect(c.focusedDate, DateTime(2026, 10, 16));
      expect(tapped, isEmpty);

      await tester.tap(find.text('16').first);
      await tester.pump();
      expect(tapped, [DateTime(2026, 10, 16)]);
    });

    testWidgets('a booking in the list reports onEventTap', (tester) async {
      TimeboardEvent? tapped;
      await _pump(
        tester,
        phone,
        TimeboardView.month,
        onEventTap: (e) => tapped = e,
      );
      await tester.scrollUntilVisible(
        find.text('Ahmed Hassan'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ahmed Hassan'));
      expect(tapped?.id, 'a2');
    });

    testWidgets('toolbar stacks: tabs and Today sit under the date', (
      tester,
    ) async {
      await _pump(tester, phone, TimeboardView.month);
      final title = tester.getTopLeft(find.text('October 2026')).dy;
      final tabs = tester.getTopLeft(find.text('Month')).dy;
      expect(tabs, greaterThan(title));
      expect(find.text('Today'), findsOneWidget);
      // Actions are icon-only on a phone.
      expect(find.text('New booking'), findsNothing);
    });

    testWidgets('week scrolls sideways and opens on today', (tester) async {
      await _pump(tester, phone, TimeboardView.week);
      final scroll = tester.state<ScrollableState>(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      // 14 Oct is the 4th column of a Sunday-first week: not at the left edge.
      expect(scroll.position.pixels, greaterThan(0));
    });

    testWidgets('agenda has no column header and shows each booking', (
      tester,
    ) async {
      await _pump(tester, phone, TimeboardView.agenda);
      expect(find.text('TIME'), findsNothing);
      expect(find.text('Ahmed Hassan'), findsOneWidget);
    });

    testWidgets('padding is smaller than on desktop', (tester) async {
      await _pump(tester, phone, TimeboardView.month);
      final padding = tester
          .widget<Padding>(
            find
                .descendant(
                  of: find.byType(Timeboard),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding;
      expect(padding, const EdgeInsets.all(12));
    });

    testWidgets('compactBelow: 0 keeps the desktop layout', (tester) async {
      await _pump(
        tester,
        phone,
        TimeboardView.month,
        options: const TimeboardOptions(compactBelow: 0),
      );
      expect(find.text('Ahmed · Sony FX3 · Pickup 10:00'), findsOneWidget);
    });
  });

  group('tablet layout', () {
    testWidgets('iPad portrait keeps chips and the full month grid', (
      tester,
    ) async {
      await _pump(tester, const Size(820, 1180), TimeboardView.month);
      expect(find.text('Ahmed · Sony FX3 · Pickup 10:00'), findsOneWidget);
    });

    testWidgets('iPad landscape keeps the single-row toolbar', (tester) async {
      await _pump(tester, const Size(1180, 820), TimeboardView.month);
      final tabs = tester.getTopLeft(find.text('Month')).dy;
      final today = tester.getTopLeft(find.text('Today')).dy;
      expect((tabs - today).abs(), lessThan(24));
    });
  });
}

void pickerOnPhones() {
  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('date picker opens on ${size.width.toInt()} wide phones', (
      tester,
    ) async {
      await _pump(tester, size, TimeboardView.month);
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TimeboardDatePicker), findsOneWidget);
    });
  }
}
