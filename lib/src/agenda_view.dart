import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_utils.dart';
import 'calendar_widgets.dart';

const _timeWidth = 160.0;
const _bookingMaxWidth = 260.0;
const _typeWidth = 100.0;
const _statusWidth = 120.0;

/// Below this the equipment and type columns are dropped: equipment moves
/// under the customer's name, and the type is left to the status chip.
const _compactBelow = 860.0;

class _Metrics {
  const _Metrics({
    required this.compact,
    required this.bookingWidth,
    this.phone = false,
  });

  final bool compact;

  /// Phone: no column header; each booking is a two-line card row.
  final bool phone;

  /// Width of the BOOKING column (full layout only; compact flexes).
  final double bookingWidth;

  double get rail => phone ? 60 : (compact ? 96 : 144);
  double get railLeft => phone ? 12 : (compact ? 16 : 24);
  double get timeWidth => compact ? 128 : _timeWidth;
  double get statusWidth => compact ? 110 : _statusWidth;
}

/// `options.agendaDays` days starting at [startDate], grouped by day.
class TimeboardAgendaView extends StatelessWidget {
  const TimeboardAgendaView({super.key, required this.startDate});

  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < _compactBelow;
        // Fixed columns (rail, row padding, time, type, status, 4 gaps) leave a
        // flexible remainder: booking gets 40% of it, capped at the design's
        // 260, so the layout holds between desktop widths too.
        const fixed =
            144 + 16 + 24 + _timeWidth + _typeWidth + _statusWidth + 64;
        final bookingWidth = ((c.maxWidth - fixed) * 0.4).clamp(
          0.0,
          _bookingMaxWidth,
        );
        return _content(
          context,
          _Metrics(
            compact: compact,
            bookingWidth: bookingWidth,
            phone: TimeboardScope.of(context).compact,
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, _Metrics m) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final days = s.options.agendaDays;

    Widget head(String text, {double? width}) {
      final label = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.text(12, FontWeight.w600, t.contentMuted, lineHeight: 16),
      );
      return width == null
          ? Expanded(child: label)
          : SizedBox(width: width, child: label);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!m.phone)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: t.surfaceCanvas,
              border: Border(bottom: BorderSide(color: t.borderGrid)),
            ),
            child: Row(
              children: [
                // Aligned to the date rail below (the Figma header sits 16px off).
                SizedBox(
                  width: m.rail,
                  child: Padding(
                    padding: EdgeInsets.only(left: m.railLeft),
                    child: Text(
                      l.agendaDay,
                      maxLines: 1,
                      style: t.text(
                        12,
                        FontWeight.w600,
                        t.contentMuted,
                        lineHeight: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 24),
                    child: Row(
                      children: [
                        head(l.agendaTime, width: m.timeWidth),
                        const SizedBox(width: 16),
                        if (m.compact) ...[
                          head(l.agendaBooking),
                          const SizedBox(width: 16),
                        ] else ...[
                          head(l.agendaBooking, width: m.bookingWidth),
                          const SizedBox(width: 16),
                          head(l.agendaEquipment),
                          const SizedBox(width: 16),
                          head(l.agendaType, width: _typeWidth),
                          const SizedBox(width: 16),
                        ],
                        head(l.agendaStatus, width: m.statusWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Flexible(
          child: ColoredBox(
            color: t.surfaceCanvas,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < days; i++)
                    _DayGroup(
                      day: addDays(startDate, i),
                      isLast: i == days - 1,
                      metrics: m,
                      events: _eventsFor(s, addDays(startDate, i)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// All-day first, time-pending last, otherwise by start time (which is how
  /// the index already orders a day, and the sort keeps ties in that order).
  List<TimeboardEvent> _eventsFor(TimeboardScope s, DateTime day) {
    final list = [...s.index.on(day)];
    int rank(TimeboardEvent e) => e.allDay ? 0 : (e.timePending ? 2 : 1);
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return list;
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.events,
    required this.isLast,
    required this.metrics,
  });

  final DateTime day;
  final List<TimeboardEvent> events;
  final bool isLast;
  final _Metrics metrics;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final isToday = s.isToday(day);
    final railText = isToday ? t.contentBrand : t.contentMuted;
    final railNumber = isToday ? t.contentBrand : t.contentPrimary;

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: t.borderGrid)),
      ),
      child: Stack(
        children: [
          // The rail's wash and divider span the whole group, whatever its
          // height: no IntrinsicHeight pass over every row.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: metrics.rail,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isToday ? t.surfaceToday : null,
                border: Border(right: BorderSide(color: t.borderGrid)),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: metrics.rail,
                padding: EdgeInsets.fromLTRB(
                  metrics.railLeft,
                  16,
                  metrics.phone ? 6 : 12,
                  16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.weekdayAbbr(day),
                      maxLines: 1,
                      style: t.text(
                        12,
                        FontWeight.w600,
                        railText,
                        lineHeight: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: t.text(
                        20,
                        FontWeight.w600,
                        railNumber,
                        lineHeight: 28,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.monthShort(day),
                      maxLines: 1,
                      style: t.text(
                        12,
                        FontWeight.w400,
                        railText,
                        lineHeight: 18,
                      ),
                    ),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            TimeboardDot(color: t.todayMarker),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l.today,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.text(
                                  11,
                                  FontWeight.w500,
                                  t.contentBrand,
                                  lineHeight: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? Container(
                        height: 40,
                        padding: const EdgeInsets.only(left: 16, right: 24),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.noBookings,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.text(
                            14,
                            FontWeight.w400,
                            t.contentMuted,
                            lineHeight: 20,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < events.length; i++)
                            _BookingRow(
                              event: events[i],
                              metrics: metrics,
                              showDivider: i < events.length - 1,
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.event,
    required this.metrics,
    required this.showDivider,
  });

  final TimeboardEvent event;
  final _Metrics metrics;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final m = metrics;
    if (m.phone) {
      return _PhoneBookingRow(event: event, showDivider: showDivider);
    }

    final time = event.allDay
        ? l.allDay
        : event.timePending
        ? l.timePending
        : l.timeRange(event.start, event.effectiveEnd);

    Text line(String text, TextStyle style) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);

    final nameStyle = t.text(
      14,
      FontWeight.w500,
      t.contentPrimary,
      lineHeight: 20,
    );
    final mutedStyle = t.text(
      12,
      FontWeight.w400,
      t.contentMuted,
      lineHeight: 18,
    );

    // Compact: no room for an equipment column, so it sits under the name,
    // and the type (Pickup / Return) joins it.
    final compactSub = [
      if (event.type.isNotEmpty) event.type,
      if (event.equipment.isNotEmpty) event.equipment,
    ].join(' · ');

    final booking = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(event.customer, nameStyle),
        if (m.compact && compactSub.isNotEmpty)
          line(compactSub, mutedStyle)
        else if (!m.compact && event.bookingNo != null)
          line(event.bookingNo!, mutedStyle),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: s.onEventTap == null ? null : () => s.onEventTap!(event),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.only(left: 16, right: 24),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: t.borderGrid))
                : null,
          ),
          child: Row(
            children: [
              SizedBox(width: m.timeWidth, child: line(time, nameStyle)),
              const SizedBox(width: 16),
              if (m.compact)
                Expanded(child: booking)
              else ...[
                SizedBox(width: m.bookingWidth, child: booking),
                const SizedBox(width: 16),
                Expanded(
                  child: line(
                    event.equipment,
                    t.text(
                      14,
                      FontWeight.w400,
                      t.contentSecondary,
                      lineHeight: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: _typeWidth,
                  child: line(
                    event.type,
                    t.text(
                      14,
                      FontWeight.w500,
                      t.contentSecondary,
                      lineHeight: 20,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              SizedBox(
                width: m.statusWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: TimeboardStatusChip(
                      event.status,
                      colors: s.colorsOf(event),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone booking row: time on top, customer, then type and equipment, with
/// the status chip scaled into the corner.
class _PhoneBookingRow extends StatelessWidget {
  const _PhoneBookingRow({required this.event, required this.showDivider});

  final TimeboardEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;

    final time = event.allDay
        ? l.allDay
        : event.timePending
        ? l.timePending
        : l.timeRange(event.start, event.effectiveEnd);
    final sub = [
      if (event.type.isNotEmpty) event.type,
      if (event.equipment.isNotEmpty) event.equipment,
    ].join(' · ');

    Text line(String text, TextStyle style) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: s.onEventTap == null ? null : () => s.onEventTap!(event),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: t.borderGrid))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(
                      time,
                      t.text(
                        12,
                        FontWeight.w500,
                        t.contentMuted,
                        lineHeight: 16,
                      ),
                    ),
                    line(
                      event.customer,
                      t.text(
                        14,
                        FontWeight.w600,
                        t.contentPrimary,
                        lineHeight: 20,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      line(
                        sub,
                        t.text(
                          12,
                          FontWeight.w400,
                          t.contentSecondary,
                          lineHeight: 16,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topRight,
                  child: TimeboardStatusChip(
                    event.status,
                    colors: s.colorsOf(event),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
