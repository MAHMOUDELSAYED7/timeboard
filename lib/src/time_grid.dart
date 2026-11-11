import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_utils.dart';

const _blockInset = 3.0;

/// Hour rows + one column per day + positioned booking blocks. Shared by the
/// week view (7 columns, 72px gutter) and the day view (1 column, 96px).
///
/// Covers the whole day and scrolls. It opens with the current hour at the
/// top, so what is happening now is the first thing on screen, and a pulsing
/// green dot marks the current time in today's column.
///
/// The grid lines are one [CustomPainter]; only the hour labels and the
/// bookings are widgets.
class TimeboardTimeGrid extends StatefulWidget {
  const TimeboardTimeGrid({
    super.key,
    required this.days,
    required this.gutterWidth,
    required this.gutterRightPadding,
    this.columnDividers = true,
  });

  final List<DateTime> days;
  final double gutterWidth;
  final double gutterRightPadding;
  final bool columnDividers;

  @override
  State<TimeboardTimeGrid> createState() => _TimeboardTimeGridState();
}

class _TimeboardTimeGridState extends State<TimeboardTimeGrid> {
  ScrollController? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scroll != null) return;
    final s = TimeboardScope.of(context);
    final o = s.options;
    // Top of the current hour, so the current time is the first row.
    final hour = o.scrollToNow
        ? s.now.hour.clamp(o.dayStartHour, o.dayEndHour - 1)
        : 0;
    final offset = o.scrollToNow ? (hour - o.dayStartHour) * o.hourHeight : 0.0;
    _scroll = ScrollController(initialScrollOffset: offset);
    // Late in the day the offset is past the end; settle on the last screen.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final c = _scroll;
      if (c == null || !c.hasClients) return;
      final max = c.position.maxScrollExtent;
      if (c.offset > max) c.jumpTo(max);
    });
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final o = s.options;
    final days = widget.days;
    final gutterWidth = widget.gutterWidth;

    return ColoredBox(
      color: t.surfaceCanvas,
      child: LayoutBuilder(
        builder: (context, c) {
          final colWidth = (c.maxWidth - gutterWidth) / days.length;

          return SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: o.hourHeight * o.hourCount,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _GridPainter(
                          color: t.borderGrid,
                          rows: o.hourCount,
                          rowHeight: o.hourHeight,
                          gutterWidth: gutterWidth,
                          columns: widget.columnDividers ? days.length : 0,
                        ),
                      ),
                    ),
                  ),
                  for (var h = o.dayStartHour; h < o.dayEndHour; h++)
                    Positioned(
                      left: 0,
                      width: gutterWidth,
                      top: (h - o.dayStartHour) * o.hourHeight + 4,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: widget.gutterRightPadding,
                        ),
                        child: Text(
                          s.labels.time(DateTime(2000, 1, 1, h)),
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: t.text(
                            11,
                            FontWeight.w400,
                            t.contentMuted,
                            lineHeight: 14,
                          ),
                        ),
                      ),
                    ),
                  for (var i = 0; i < days.length; i++)
                    ..._blocksFor(
                      s,
                      day: days[i],
                      left: gutterWidth + i * colWidth,
                      width: colWidth,
                    ),
                  // Not wrapped in IgnorePointer: the dot has a tooltip. The layer
                  // only has a child where the dot is, so everything else under
                  // it still gets its taps.
                  if (o.showNowIndicator)
                    Positioned.fill(child: _NowLayer(days: days)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _blocksFor(
    TimeboardScope s, {
    required DateTime day,
    required double left,
    required double width,
  }) {
    final o = s.options;
    final hourHeight = o.hourHeight;
    final minVisible = o.dayStartHour * 60;
    final maxVisible = o.dayEndHour * 60;

    // Greedy lane assignment so overlapping bookings sit side by side. The
    // index already sorted the day by start time.
    final spans = <_Span>[];
    for (final e in s.index.on(day)) {
      if (e.isUntimed) continue;
      final startMin = isSameDay(e.start, day)
          ? e.start.hour * 60 + e.start.minute
          : 0;
      final end = e.effectiveEnd;
      final endMin = isSameDay(end, day) ? end.hour * 60 + end.minute : 24 * 60;
      final lo = startMin.clamp(minVisible, maxVisible);
      final hi = endMin.clamp(minVisible, maxVisible);
      if (hi <= lo) continue;
      spans.add(_Span(e, lo, hi));
    }

    final laneEnds = <int>[];
    for (final sp in spans) {
      var lane = laneEnds.indexWhere((end) => end <= sp.start);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(sp.end);
      } else {
        laneEnds[lane] = sp.end;
      }
      sp.lane = lane;
    }
    // Each span's width is split by the widest overlap cluster it belongs to.
    for (final sp in spans) {
      var lanes = 1;
      for (final other in spans) {
        if (other.start < sp.end && other.end > sp.start) {
          lanes = lanes > other.lane + 1 ? lanes : other.lane + 1;
        }
      }
      sp.lanes = lanes;
    }

    return [
      for (final sp in spans)
        _positioned(s, sp, left, width, hourHeight, minVisible),
    ];
  }

  Widget _positioned(
    TimeboardScope s,
    _Span sp,
    double left,
    double width,
    double hourHeight,
    int minVisible,
  ) {
    final top = (sp.start - minVisible) / 60 * hourHeight;
    final h = ((sp.end - sp.start) / 60 * hourHeight - 2).clamp(
      28.0,
      double.infinity,
    );
    final laneWidth = (width - _blockInset * 2) / sp.lanes;
    return Positioned(
      left: left + _blockInset + laneWidth * sp.lane,
      width: laneWidth - (sp.lanes > 1 ? 2 : 0),
      top: top + 1,
      height: h,
      child: _Block(event: sp.event, height: h),
    );
  }
}

/// Hour and column lines in one paint call: the bottom edge of every hour
/// row, the gutter's right edge, and the right edge of every day column.
class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.color,
    required this.rows,
    required this.rowHeight,
    required this.gutterWidth,
    required this.columns,
  });

  final Color color;
  final int rows;
  final double rowHeight;
  final double gutterWidth;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    // 0.5 puts a 1px line inside the cell edge, as a box border would.
    for (var i = 1; i <= rows; i++) {
      final y = i * rowHeight - 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawLine(
      Offset(gutterWidth - 0.5, 0),
      Offset(gutterWidth - 0.5, size.height),
      paint,
    );
    if (columns > 0) {
      final colWidth = (size.width - gutterWidth) / columns;
      for (var i = 1; i <= columns; i++) {
        final x = gutterWidth + i * colWidth - 0.5;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color ||
      old.rows != rows ||
      old.rowHeight != rowHeight ||
      old.gutterWidth != gutterWidth ||
      old.columns != columns;
}

class _Span {
  _Span(this.event, this.start, this.end);
  final TimeboardEvent event;
  final int start;
  final int end;
  int lane = 0;
  int lanes = 1;
}

class _Block extends StatelessWidget {
  const _Block({required this.event, required this.height});
  final TimeboardEvent event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final c = s.colorsOf(event);

    final detail = event.timePending
        ? s.labels.timePending
        : [
            event.type,
            s.labels.time(event.start),
          ].where((p) => p.isNotEmpty).join(' · ');
    final compact = height < 56;

    return s.eventWidget(
      context,
      event,
      TimeboardEventSlot.timeBlock,
      () => Material(
        color: c.fill,
        borderRadius: BorderRadius.circular(t.chipRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: s.onEventTap == null ? null : () => s.onEventTap!(event),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 6 : 12,
            ),
            // Scroll view with no physics = clip instead of overflow error
            // when a short booking cannot show both lines.
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.text(12, FontWeight.w600, c.text),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(10, FontWeight.w400, c.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The current-time marker. A layer of its own with its own timer, so it
/// moves by itself every half minute without rebuilding the grid or the
/// bookings under it.
class _NowLayer extends StatefulWidget {
  const _NowLayer({required this.days});

  final List<DateTime> days;

  @override
  State<_NowLayer> createState() => _NowLayerState();
}

class _NowLayerState extends State<_NowLayer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  AnimationController? _pulse;
  int _shownMinute = -1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final now = TimeboardScope.of(context).now;
      final minute = now.hour * 60 + now.minute;
      if (minute != _shownMinute) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = TimeboardScope.of(context).options.animateNowIndicator;
    if (animate && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    } else if (!animate && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final o = s.options;
    final now = s.now;
    final minutes = now.hour * 60 + now.minute;
    _shownMinute = minutes;
    final visible =
        widget.days.any((d) => isSameDay(d, now)) &&
        minutes >= o.dayStartHour * 60 &&
        minutes < o.dayEndHour * 60;
    if (!visible) return const SizedBox.shrink();

    final y = (minutes - o.dayStartHour * 60) / 60 * o.hourHeight;
    final t = s.theme;

    return Stack(
      children: [
        Positioned(
          // In the hour gutter, at the current minute: the cell that carries
          // the hour labels. No booking is ever drawn there, so the dot can
          // neither cover an order nor push one aside, whatever is booked at
          // this time.
          left: 0,
          top: y - _dotBox / 2,
          width: _dotBox,
          height: _dotBox,
          child: Tooltip(
            message: '${s.labels.currentTime} · ${s.labels.time(now)}',
            // Hover on desktop, tap or long press elsewhere.
            triggerMode: TooltipTriggerMode.tap,
            waitDuration: const Duration(milliseconds: 100),
            preferBelow: false,
            textStyle: t.text(
              12,
              FontWeight.w500,
              t.surfaceCanvas,
              lineHeight: 16,
            ),
            decoration: BoxDecoration(
              color: t.contentPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            // Its own layer: the pulse repaints only the dot, never the grid.
            child: RepaintBoundary(
              child: _PulsingDot(
                key: const ValueKey('timeboard-now-dot'),
                color: t.todayMarker,
                animation: _pulse,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Room for the halo at its widest.
const _dotBox = 18.0;
const _dotSize = 8.0;

/// A solid dot that swells and shrinks inside a halo that spreads and fades:
/// "this is now".
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({super.key, required this.color, this.animation});

  final Color color;

  /// Null draws the dot still, with no halo.
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    if (animation == null) {
      return Center(
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = Curves.easeInOut.transform(animation.value);
        final halo = _dotSize + (_dotBox - _dotSize) * v;
        final core = _dotSize * (0.85 + 0.35 * v);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: halo,
                height: halo,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.35 * (1 - v)),
                ),
              ),
              Container(
                width: core,
                height: core,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
