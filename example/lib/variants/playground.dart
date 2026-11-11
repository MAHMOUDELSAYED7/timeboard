import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';

import '../demo_data.dart';

/// 4 · Playground: every option and theme token on a live control panel, so a
/// change shows up immediately.
class Playground extends StatefulWidget {
  const Playground({super.key});

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  static const _brands = {
    'Default': null,
    'Teal': Color(0xFF0F9D8A),
    'Rose': Color(0xFFD81B60),
    'Orange': Color(0xFFF57C00),
    'Indigo': Color(0xFF3F51B5),
  };

  var _events = buildDemoEvents();
  var _eventCount = 0; // 0 = the small hand-made demo set

  var _options = const TimeboardOptions();
  var _use24Hour = false;
  var _datePicker = true;
  var _firstWeekday = DateTime.sunday;
  var _radius = 16.0;
  var _brand = 'Default';
  var _byCustomer = false;
  var _panelOpen = true;

  void _reset() => setState(() {
    _options = const TimeboardOptions();
    _use24Hour = false;
    _datePicker = true;
    _firstWeekday = DateTime.sunday;
    _radius = 16;
    _brand = 'Default';
    _byCustomer = false;
    _setEventCount(0);
  });

  /// 0 keeps the readable demo data; anything else generates that many
  /// bookings over the surrounding two months, to try the calendar under load.
  void _setEventCount(int n) {
    _eventCount = n;
    _events = n == 0 ? buildDemoEvents() : _generate(n);
  }

  static List<TimeboardEvent> _generate(int n) {
    final start = DateTime.now().subtract(const Duration(days: 30));
    return [
      for (var i = 0; i < n; i++)
        TimeboardEvent(
          id: 'g$i',
          customer: 'Customer ${i % 97}',
          equipment: ['Laptop', 'Monitor', 'Desk lamp', 'Headphones'][i % 4],
          bookingNo: 'Booking #${2000 + i}',
          type: i.isEven ? 'Pickup' : 'Return',
          status: TimeboardBookingStatus.values[i % 5],
          start: DateTime(
            start.year,
            start.month,
            start.day + (i * 7) % 60,
            8 + i % 10,
            (i % 4) * 15,
          ),
          end: DateTime(
            start.year,
            start.month,
            start.day + (i * 7) % 60,
            9 + i % 10,
            (i % 4) * 15,
          ),
        ),
    ];
  }

  void _opt(TimeboardOptions Function(TimeboardOptions o) f) =>
      setState(() => _options = f(_options));

  TimeboardTheme _theme(Brightness b) {
    final seed = _brands[_brand];
    final base = seed == null
        ? (b == Brightness.dark ? TimeboardTheme.dark : TimeboardTheme.light)
        : TimeboardTheme.fromSeed(seed, brightness: b);
    return base.copyWith(
      panelRadius: _radius,
      chipRadius: _radius / 2,
      controlRadius: _radius * .6,
    );
  }

  // Stable colour per customer, to show eventColors.
  TimeboardStatusColors _customerColors(TimeboardEvent e, TimeboardTheme t) {
    final hue = (e.customer.hashCode % 360).toDouble();
    final dark = t.surfaceCanvas.computeLuminance() < .5;
    return TimeboardStatusColors(
      fill: HSLColor.fromAHSL(1, hue, .55, dark ? .22 : .88).toColor(),
      text: HSLColor.fromAHSL(1, hue, .6, dark ? .82 : .28).toColor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final theme = _theme(b);
    final calendar = Timeboard(
      events: _events,
      theme: theme,
      options: _options,
      labels: TimeboardLabels(use24Hour: _use24Hour),
      firstWeekday: _firstWeekday,
      enableDatePicker: _datePicker,
      eventColors: _byCustomer ? _customerColors : null,
      onEventTap: (e) => showEventDialog(context, e),
      onNewBooking: () => showSnack(context, 'onNewBooking'),
      onFilters: () => showSnack(context, 'onFilters'),
    );

    // Phones: the controls slide in from the right; wider screens keep them
    // docked beside the calendar.
    if (MediaQuery.sizeOf(context).width < 900) {
      return Scaffold(
        endDrawer: Drawer(child: SafeArea(child: _controls())),
        body: Stack(
          children: [
            calendar,
            Positioned(
              right: 8,
              bottom: 8,
              child: Builder(
                builder: (context) => FloatingActionButton.small(
                  tooltip: 'Parameters',
                  onPressed: Scaffold.of(context).openEndDrawer,
                  child: const Icon(Icons.tune),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: calendar),
        if (_panelOpen) SizedBox(width: 300, child: _controls()),
        IconButton(
          tooltip: 'Controls',
          onPressed: () => setState(() => _panelOpen = !_panelOpen),
          icon: Icon(_panelOpen ? Icons.chevron_right : Icons.tune),
        ),
      ],
    );
  }

  Widget _controls() {
    final o = _options;
    Widget sw(String label, bool v, ValueChanged<bool> f) =>
        SwitchListTile(dense: true, title: Text(label), value: v, onChanged: f);
    Widget slider(
      String label,
      double v,
      double min,
      double max,
      ValueChanged<double> f, {
      int? divisions,
    }) => ListTile(
      dense: true,
      title: Text('$label: ${v.round()}'),
      subtitle: Slider(
        value: v,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: f,
      ),
    );
    Widget section(String title, List<Widget> children, {bool open = false}) =>
        ExpansionTile(
          title: Text(title),
          initiallyExpanded: open,
          shape: const Border(),
          collapsedShape: const Border(),
          children: children,
        );

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          ListTile(
            title: const Text('Parameters'),
            subtitle: Text('${_events.length} bookings'),
            trailing: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                section('Theme', [
                  ListTile(
                    dense: true,
                    title: const Text('Brand colour'),
                    trailing: DropdownButton<String>(
                      value: _brand,
                      items: [
                        for (final k in _brands.keys)
                          DropdownMenuItem(value: k, child: Text(k)),
                      ],
                      onChanged: (v) => setState(() => _brand = v!),
                    ),
                  ),
                  slider(
                    'Corner radius',
                    _radius,
                    0,
                    28,
                    (v) => setState(() => _radius = v),
                  ),
                  sw(
                    'Colour by customer (eventColors)',
                    _byCustomer,
                    (v) => setState(() => _byCustomer = v),
                  ),
                ], open: true),
                section('Month & agenda', [
                  slider(
                    'Chips per day',
                    o.maxChipsPerDay.toDouble(),
                    0,
                    6,
                    (v) => _opt((o) => o.copyWith(maxChipsPerDay: v.round())),
                    divisions: 6,
                  ),
                  slider(
                    'Chip height',
                    o.monthChipHeight,
                    16,
                    40,
                    (v) => _opt((o) => o.copyWith(monthChipHeight: v)),
                    divisions: 12,
                  ),
                  slider(
                    'Min row height',
                    o.minMonthRowHeight,
                    90,
                    240,
                    (v) => _opt((o) => o.copyWith(minMonthRowHeight: v)),
                    divisions: 15,
                  ),
                  slider(
                    'Agenda days',
                    o.agendaDays.toDouble(),
                    1,
                    14,
                    (v) => _opt((o) => o.copyWith(agendaDays: v.round())),
                    divisions: 13,
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('First weekday'),
                    trailing: DropdownButton<int>(
                      value: _firstWeekday,
                      items: const [
                        DropdownMenuItem(
                          value: DateTime.sunday,
                          child: Text('Sunday'),
                        ),
                        DropdownMenuItem(
                          value: DateTime.monday,
                          child: Text('Monday'),
                        ),
                        DropdownMenuItem(
                          value: DateTime.saturday,
                          child: Text('Saturday'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _firstWeekday = v!),
                    ),
                  ),
                  sw(
                    'Weekend shading (Fri + Sat)',
                    o.weekendDays.isNotEmpty,
                    (v) => _opt(
                      (o) => o.copyWith(
                        weekendDays: v
                            ? {DateTime.friday, DateTime.saturday}
                            : {},
                      ),
                    ),
                  ),
                ]),
                section('Week & day timeline', [
                  slider(
                    'Hour height',
                    o.hourHeight,
                    40,
                    120,
                    (v) => _opt((o) => o.copyWith(hourHeight: v)),
                    divisions: 16,
                  ),
                  ListTile(
                    dense: true,
                    title: Text('Hours: ${o.dayStartHour} – ${o.dayEndHour}'),
                    subtitle: RangeSlider(
                      values: RangeValues(
                        o.dayStartHour.toDouble(),
                        o.dayEndHour.toDouble(),
                      ),
                      min: 0,
                      max: 24,
                      divisions: 24,
                      onChanged: (r) => r.end - r.start < 1
                          ? null
                          : _opt(
                              (o) => o.copyWith(
                                dayStartHour: r.start.round(),
                                dayEndHour: r.end.round(),
                              ),
                            ),
                    ),
                  ),
                  sw(
                    '24-hour clock',
                    _use24Hour,
                    (v) => setState(() => _use24Hour = v),
                  ),
                  sw(
                    'Scroll to now',
                    o.scrollToNow,
                    (v) => _opt((o) => o.copyWith(scrollToNow: v)),
                  ),
                  sw(
                    'Show "now" dot',
                    o.showNowIndicator,
                    (v) => _opt((o) => o.copyWith(showNowIndicator: v)),
                  ),
                  sw(
                    'Pulse "now" dot',
                    o.animateNowIndicator,
                    (v) => _opt((o) => o.copyWith(animateNowIndicator: v)),
                  ),
                ]),
                section('Toolbar & views', [
                  sw(
                    'Toolbar',
                    o.showToolbar,
                    (v) => _opt((o) => o.copyWith(showToolbar: v)),
                  ),
                  sw(
                    'Today button',
                    o.showTodayButton,
                    (v) => _opt((o) => o.copyWith(showTodayButton: v)),
                  ),
                  sw(
                    'View switcher',
                    o.showViewSwitcher,
                    (v) => _opt((o) => o.copyWith(showViewSwitcher: v)),
                  ),
                  sw(
                    'Filters',
                    o.showFilters,
                    (v) => _opt((o) => o.copyWith(showFilters: v)),
                  ),
                  sw(
                    'New booking',
                    o.showNewBooking,
                    (v) => _opt((o) => o.copyWith(showNewBooking: v)),
                  ),
                  sw(
                    'Date picker on title',
                    _datePicker,
                    (v) => setState(() => _datePicker = v),
                  ),
                  for (final v in TimeboardView.values)
                    CheckboxListTile(
                      dense: true,
                      title: Text('View: ${v.name}'),
                      value: o.views.contains(v),
                      onChanged: (on) {
                        final next = [
                          for (final x in TimeboardView.values)
                            if (x == v ? on! : o.views.contains(x)) x,
                        ];
                        if (next.isNotEmpty) {
                          _opt((o) => o.copyWith(views: next));
                        }
                      },
                    ),
                ]),
                section('Performance test', [
                  ListTile(
                    dense: true,
                    title: const Text('Bookings'),
                    trailing: DropdownButton<int>(
                      value: _eventCount,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Demo set')),
                        DropdownMenuItem(value: 200, child: Text('200')),
                        DropdownMenuItem(value: 1000, child: Text('1,000')),
                        DropdownMenuItem(value: 5000, child: Text('5,000')),
                      ],
                      onChanged: (v) => setState(() => _setEventCount(v!)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
