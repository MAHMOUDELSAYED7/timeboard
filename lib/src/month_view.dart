import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_utils.dart';
import 'calendar_widgets.dart';

const _chipGap = 4.0;
const _moreHeight = 22.0;

/// Six weeks of day cells starting on the host's first weekday.
class TimeboardMonthView extends StatelessWidget {
  const TimeboardMonthView({super.key, required this.focusedDate});

  final DateTime focusedDate;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    if (s.compact) return _CompactMonth(focusedDate: focusedDate);
    final t = s.theme;
    final first = DateTime(focusedDate.year, focusedDate.month, 1);
    final gridStart = startOfWeek(first, s.firstWeekday);
    final minRow = s.options.minMonthRowHeight;

    return Column(
      children: [
        Container(
          height: 48,
          color: t.surfaceCanvas,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surfaceCanvas,
                      border: Border(
                        bottom: BorderSide(color: t.borderGrid),
                        right: BorderSide(color: t.borderGrid),
                      ),
                    ),
                    child: Text(
                      s.labels.weekdayAbbr(addDays(gridStart, i)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        11,
                        FontWeight.w600,
                        t.contentMuted,
                        lineHeight: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final height = c.maxHeight < minRow * 6
                  ? minRow * 6
                  : c.maxHeight;
              return SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: Column(
                    children: [
                      for (var w = 0; w < 6; w++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var d = 0; d < 7; d++)
                                Expanded(
                                  child: _DayCell(
                                    day: addDays(gridStart, w * 7 + d),
                                    inMonth:
                                        addDays(gridStart, w * 7 + d).month ==
                                        focusedDate.month,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.inMonth});

  final DateTime day;
  final bool inMonth;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final isToday = s.isToday(day);
    final events = s.index.on(day);

    final fill = isToday
        ? t.surfaceToday
        : s.isWeekend(day)
        ? t.surfaceSubtle
        : t.surfaceCanvas;

    final numberStyle = isToday
        ? t.text(13, FontWeight.w700, t.contentBrand)
        : t.text(
            13,
            FontWeight.w500,
            inMonth ? t.contentPrimary : t.contentMuted,
          );

    return Material(
      color: fill,
      child: InkWell(
        onTap: s.onDayTap == null ? null : () => s.onDayTap!(day),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: t.borderGrid),
              right: BorderSide(color: t.borderGrid),
            ),
          ),
          // A cell squeezed below its content must clip, not throw a
          // RenderFlex overflow.
          child: LayoutBuilder(
            builder: (context, c) {
              final shown = _chipsThatFit(
                total: events.length,
                cap: s.options.maxChipsPerDay,
                chipHeight: s.options.monthChipHeight,
                available: c.maxHeight - _headerHeight,
              );
              final hidden = events.length - shown;
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    width: c.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${day.day}',
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: numberStyle,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              TimeboardDot(color: t.todayMarker),
                            ],
                          ],
                        ),
                        if (events.isNotEmpty) const SizedBox(height: 6),
                        for (var i = 0; i < shown; i++) ...[
                          if (i > 0) const SizedBox(height: _chipGap),
                          TimeboardEventChip(
                            event: events[i],
                            slot: TimeboardEventSlot.monthChip,
                            label: events[i].monthLabel,
                            height: s.options.monthChipHeight,
                            outline: isToday,
                            solidDraft: true,
                          ),
                        ],
                        if (hidden > 0) ...[
                          const SizedBox(height: _chipGap),
                          TimeboardMoreChip(
                            count: hidden,
                            height: _moreHeight,
                            onTap: s.onDayTap == null
                                ? null
                                : () => s.onDayTap!(day),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The day number row plus the gap under it.
const _headerHeight = 23.0;

/// How many chips a cell shows: as many as [cap] allows, but never so many
/// that the "+N more" row (needed when some are hidden) falls out of the
/// cell and gets clipped. A cell too short for any chip shows just "+N more".
int _chipsThatFit({
  required int total,
  required int cap,
  required double chipHeight,
  required double available,
}) {
  var shown = total < cap ? total : cap;
  if (!available.isFinite) return shown;
  for (; shown > 0; shown--) {
    final chips = shown * chipHeight + (shown - 1) * _chipGap;
    final more = shown < total ? _chipGap + _moreHeight : 0;
    if (chips + more <= available) return shown;
  }
  return 0;
}

const _compactRowHeight = 52.0;
const _compactDotSize = 6.0;
const _compactMaxDots = 3;

/// Phone month: a grid of day numbers with one dot per booking (the first
/// few), and below it the bookings of the selected day. Chips would be
/// unreadable at ~50px per column, so the detail moves to the list.
///
/// Tapping a day selects it; tapping the selected day again reports
/// `onDayTap`, so the host can still open its own day screen.
class _CompactMonth extends StatelessWidget {
  const _CompactMonth({required this.focusedDate});

  final DateTime focusedDate;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final first = DateTime(focusedDate.year, focusedDate.month, 1);
    final gridStart = startOfWeek(first, s.firstWeekday);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderGrid)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        s.labels.weekdayAbbr(addDays(gridStart, i)),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: t.text(
                          10,
                          FontWeight.w600,
                          t.contentMuted,
                          lineHeight: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var w = 0; w < 6; w++)
            SizedBox(
              height: _compactRowHeight,
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _CompactCell(
                        day: addDays(gridStart, w * 7 + d),
                        inMonth:
                            addDays(gridStart, w * 7 + d).month ==
                            focusedDate.month,
                        selected: isSameDay(
                          addDays(gridStart, w * 7 + d),
                          focusedDate,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          _SelectedDayList(day: focusedDate),
        ],
      ),
    );
  }
}

class _CompactCell extends StatelessWidget {
  const _CompactCell({
    required this.day,
    required this.inMonth,
    required this.selected,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final isToday = s.isToday(day);
    final events = s.index.on(day);

    final numberColor = selected
        ? t.contentOnAction
        : isToday
        ? t.contentBrand
        : inMonth
        ? t.contentPrimary
        : t.contentMuted;

    return Material(
      color: s.isWeekend(day) ? t.surfaceSubtle : t.surfaceCanvas,
      child: InkWell(
        onTap: () {
          if (selected) {
            s.onDayTap?.call(day);
          } else {
            s.onSelectDay?.call(day);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: t.borderGrid),
              right: BorderSide(color: t.borderGrid),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? t.actionPrimary
                      : t.surfaceToday.withValues(alpha: isToday ? 1 : 0),
                ),
                child: Text(
                  '${day.day}',
                  style: t.text(
                    13,
                    isToday || selected ? FontWeight.w700 : FontWeight.w500,
                    numberColor,
                    lineHeight: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: _compactDotSize,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var i = 0;
                      i < events.length && i < _compactMaxDots;
                      i++
                    ) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Container(
                        width: _compactDotSize,
                        height: _compactDotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.colorsOf(events[i], solidDraft: true).text,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bookings of the selected day under the compact month.
class _SelectedDayList extends StatelessWidget {
  const _SelectedDayList({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final events = s.index.on(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            '${l.weekdayName(day)}, ${day.day} ${l.monthShort(day)}',
            style: t.text(
              14,
              FontWeight.w600,
              t.contentPrimary,
              lineHeight: 20,
            ),
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              l.noBookings,
              style: t.text(
                13,
                FontWeight.w400,
                t.contentMuted,
                lineHeight: 18,
              ),
            ),
          )
        else
          for (final e in events) _DayListTile(event: e),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayListTile extends StatelessWidget {
  const _DayListTile({required this.event});

  final TimeboardEvent event;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final c = s.colorsOf(event, solidDraft: true);

    final when = event.allDay
        ? l.allDay
        : event.timePending
        ? l.timePending
        : l.timeRange(event.start, event.effectiveEnd);
    final sub = [
      if (event.type.isNotEmpty) event.type,
      if (event.equipment.isNotEmpty) event.equipment,
    ].join(' · ');

    return InkWell(
      onTap: s.onEventTap == null ? null : () => s.onEventTap!(event),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: c.text,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        12,
                        FontWeight.w500,
                        t.contentMuted,
                        lineHeight: 16,
                      ),
                    ),
                    Text(
                      event.customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        14,
                        FontWeight.w600,
                        t.contentPrimary,
                        lineHeight: 20,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.text(
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
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.fill,
                    borderRadius: BorderRadius.circular(t.chipRadius),
                  ),
                  child: Text(
                    l.statusName(event.status),
                    style: t.text(11, FontWeight.w600, c.text, lineHeight: 14),
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
