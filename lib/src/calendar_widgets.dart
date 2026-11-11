import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_theme.dart';

/// Tinted package icon, drawn in code (no asset or SVG dependency).
/// Names: `chevron_left`, `chevron_right`, `filter`, `plus`.
class TimeboardIcon extends StatelessWidget {
  const TimeboardIcon(
    this.name, {
    super.key,
    required this.color,
    this.size = 18,
  });

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _IconPainter(name, color));
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.name, this.color);

  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Designed on an 18x18 grid.
    canvas.scale(size.width / 18, size.height / 18);
    final path = Path();
    void line(double x1, double y1, double x2, double y2) => path
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
    switch (name) {
      case 'chevron_left':
        path
          ..moveTo(11.25, 13.5)
          ..lineTo(6.75, 9)
          ..lineTo(11.25, 4.5);
      case 'chevron_right':
        path
          ..moveTo(6.75, 13.5)
          ..lineTo(11.25, 9)
          ..lineTo(6.75, 4.5);
      case 'filter':
        line(3, 4.5, 15, 4.5);
        line(5.25, 9, 12.75, 9);
        line(7.5, 13.5, 10.5, 13.5);
      case 'plus':
        line(9, 3.75, 9, 14.25);
        line(3.75, 9, 14.25, 9);
      default:
        assert(false, 'Unknown TimeboardIcon "$name"');
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.name != name || old.color != color;
}

/// One-line booking pill used by the month cells, the week all-day strip and
/// the day all-day row. The host can replace it per [slot] with
/// `Timeboard.eventBuilder`.
class TimeboardEventChip extends StatelessWidget {
  const TimeboardEventChip({
    super.key,
    required this.event,
    required this.slot,
    this.label,
    this.height,
    this.horizontalPadding = 10,
    this.verticalPadding = 0,
    this.fontSize = 11,
    this.lineHeight = 16,
    this.outline = false,
    this.solidDraft = false,
  });

  final TimeboardEvent event;
  final TimeboardEventSlot slot;

  /// Defaults to the event's title.
  final String? label;

  /// Fixed height; null wraps the text and the chip takes its natural width.
  final double? height;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double lineHeight;

  /// A hairline in the chip's own text colour (bookings on today's cell).
  final bool outline;
  final bool solidDraft;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    return s.eventWidget(context, event, slot, () {
      final t = s.theme;
      final c = s.colorsOf(event, solidDraft: solidDraft);
      return Material(
        color: c.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.chipRadius),
          side: outline
              ? BorderSide(color: c.text.withValues(alpha: 0.5))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: s.onEventTap == null ? null : () => s.onEventTap!(event),
          child: Container(
            height: height,
            width: height == null ? null : double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              label ?? event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.text(
                fontSize,
                FontWeight.w600,
                c.text,
                lineHeight: lineHeight,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// The "+N more" pill that closes a day's list of chips.
class TimeboardMoreChip extends StatelessWidget {
  const TimeboardMoreChip({
    super.key,
    required this.count,
    required this.height,
    this.horizontalPadding = 10,
    this.onTap,
  });

  final int count;
  final double height;
  final double horizontalPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(t.chipRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            child: Text(
              s.labels.moreLabel(count),
              maxLines: 1,
              style: t.text(
                11,
                FontWeight.w600,
                t.contentBrand,
                lineHeight: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 6px "today" / "conflict" dot.
class TimeboardDot extends StatelessWidget {
  const TimeboardDot({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Status pill used in the agenda. Conflict is an auto-width pill with a
/// leading dot; every other status is a fixed 110x32 chip.
class TimeboardStatusChip extends StatelessWidget {
  const TimeboardStatusChip(this.status, {super.key, this.colors});
  final TimeboardBookingStatus status;

  /// Overrides the theme's colours for [status] (the host's `eventColors`).
  final TimeboardStatusColors? colors;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final c = colors ?? s.theme.statusColors(status);
    final name = s.labels.statusName(status);

    if (status == TimeboardBookingStatus.conflict) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimeboardDot(color: s.theme.error),
            const SizedBox(width: 8),
            Text(
              name,
              style: s.theme.text(12, FontWeight.w600, c.text, lineHeight: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 110,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        maxLines: 1,
        style: s.theme.text(12, FontWeight.w600, c.text),
      ),
    );
  }
}
