import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_utils.dart';
import 'calendar_widgets.dart';
import 'time_grid.dart';

const _gutterWidth = 72.0;
const _compactGutterWidth = 56.0;
const _stripChipHeight = 24.0;
const _stripGap = 4.0;

class TimeboardWeekView extends StatelessWidget {
  const TimeboardWeekView({super.key, required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final days = [for (var i = 0; i < 7; i++) addDays(weekStart, i)];
    final gutter = s.compact ? _compactGutterWidth : _gutterWidth;

    Widget content() => Column(
      children: [
        SizedBox(
          // Grows with the user's text size so the two lines always fit.
          height: 64 * _textScale(context),
          child: Row(
            children: [
              Container(
                width: gutter,
                decoration: BoxDecoration(
                  color: s.theme.surfaceCanvas,
                  border: Border(
                    right: BorderSide(color: s.theme.borderGrid),
                    bottom: BorderSide(color: s.theme.borderGrid),
                  ),
                ),
              ),
              for (final d in days) Expanded(child: _DayHeader(day: d)),
            ],
          ),
        ),
        _AllDayStrip(days: days, gutterWidth: gutter),
        Expanded(
          child: TimeboardTimeGrid(
            days: days,
            gutterWidth: gutter,
            gutterRightPadding: s.compact ? 6 : 10,
          ),
        ),
      ],
    );

    if (!s.compact) return content();

    // Seven columns do not fit a phone: keep them a readable width and let
    // the week scroll sideways, opening on today's column.
    final column = s.options.compactWeekColumnWidth;
    final minWidth = gutter + 7 * column;
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= minWidth) return content();
        final todayIndex = days.indexWhere(s.isToday);
        return _SideScroll(
          key: ValueKey(weekStart),
          initialOffset: todayIndex <= 0 ? 0 : (todayIndex - 1) * column,
          child: SizedBox(width: minWidth, child: content()),
        );
      },
    );
  }
}

/// A horizontal scroll view that opens at [initialOffset].
class _SideScroll extends StatefulWidget {
  const _SideScroll({
    super.key,
    required this.initialOffset,
    required this.child,
  });

  final double initialOffset;
  final Widget child;

  @override
  State<_SideScroll> createState() => _SideScrollState();
}

class _SideScrollState extends State<_SideScroll> {
  late final _controller = ScrollController(
    initialScrollOffset: widget.initialOffset,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _controller,
    scrollDirection: Axis.horizontal,
    child: widget.child,
  );
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final isToday = s.isToday(day);

    return Material(
      color: isToday
          ? t.surfaceToday
          : s.isWeekend(day)
          ? t.surfaceSubtle
          : t.surfaceCanvas,
      child: InkWell(
        onTap: s.onDayTap == null ? null : () => s.onDayTap!(day),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: t.borderGrid),
              bottom: BorderSide(color: t.borderGrid),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.labels.weekdayAbbr(day),
                style: t.text(
                  12,
                  FontWeight.w600,
                  isToday ? t.contentBrand : t.contentMuted,
                  lineHeight: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: t.text(
                  18,
                  FontWeight.w600,
                  isToday ? t.contentBrand : t.contentPrimary,
                  lineHeight: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bookings with no time of day (whole-day hires) have no slot on the hour
/// grid, so they sit in a strip under the day headers. Hidden when the week
/// has none, which keeps the design's layout for time-based data.
class _AllDayStrip extends StatelessWidget {
  const _AllDayStrip({required this.days, required this.gutterWidth});

  final List<DateTime> days;
  final double gutterWidth;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final maxChips = s.options.maxChipsPerDay;

    final perDay = [
      for (final d in days)
        [
          for (final e in s.index.on(d))
            if (e.isUntimed) e,
        ],
    ];
    final longest = perDay.fold<int>(0, (m, l) => l.length > m ? l.length : m);
    if (longest == 0) return const SizedBox.shrink();

    final chips = longest < maxChips ? longest : maxChips;
    // One more row, for "+N more", when any day has more than it shows.
    final rows = chips + (longest > maxChips ? 1 : 0);
    // 4px padding top and bottom, plus the 1px bottom border.
    final height = 9 + rows * _stripChipHeight + (rows - 1) * _stripGap;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: t.surfaceCanvas,
        border: Border(bottom: BorderSide(color: t.borderGrid)),
      ),
      child: Row(
        children: [
          Container(
            width: gutterWidth,
            padding: const EdgeInsets.only(right: 10, top: 6),
            alignment: Alignment.topRight,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: t.borderGrid)),
            ),
            child: Text(
              s.labels.allDay,
              maxLines: 1,
              style: t.text(
                10,
                FontWeight.w600,
                t.contentMuted,
                lineHeight: 14,
              ),
            ),
          ),
          for (var i = 0; i < perDay.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: t.borderGrid)),
                ),
                child: _DayChips(day: days[i], events: perDay[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  const _DayChips({required this.day, required this.events});

  final DateTime day;
  final List<TimeboardEvent> events;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final maxChips = s.options.maxChipsPerDay;
    final overflow = events.length > maxChips;
    final shown = overflow ? maxChips : events.length;

    return Column(
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0) const SizedBox(height: _stripGap),
          TimeboardEventChip(
            event: events[i],
            slot: TimeboardEventSlot.allDayChip,
            height: _stripChipHeight,
            horizontalPadding: 8,
          ),
        ],
        if (overflow) ...[
          const SizedBox(height: _stripGap),
          TimeboardMoreChip(
            count: events.length - shown,
            height: _stripChipHeight,
            horizontalPadding: 8,
            onTap: s.onDayTap == null ? null : () => s.onDayTap!(day),
          ),
        ],
      ],
    );
  }
}

/// How much bigger than 1.0 the user's text setting makes text (never less).
double _textScale(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
  return scale < 1 ? 1 : scale;
}
