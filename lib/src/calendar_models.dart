import 'package:flutter/widgets.dart';

import 'calendar_theme.dart';
import 'calendar_utils.dart';

enum TimeboardView { month, week, day, agenda }

/// Where an event is being drawn. Passed to [TimeboardEventBuilder] so one builder
/// can render the month chip, the all-day chip and the timeline block
/// differently. The parent fixes the size; the builder fills it.
enum TimeboardEventSlot { monthChip, allDayChip, timeBlock }

/// Replaces the default look of an event in the month, all-day and timeline
/// slots. Return null to keep the default for that event.
typedef TimeboardEventBuilder =
    Widget? Function(
      BuildContext context,
      TimeboardEvent event,
      TimeboardEventSlot slot,
    );

/// Picks the fill and text colours of an event. Defaults to
/// `theme.statusColors(event.status)`.
typedef TimeboardEventColors =
    TimeboardStatusColors Function(TimeboardEvent event, TimeboardTheme theme);

enum TimeboardBookingStatus {
  confirmed,
  out,
  returned,
  draft,
  conflict,

  /// Still out past its return date. Drawn in the conflict colours.
  overdue,

  /// Drawn in the draft colours.
  cancelled,

  /// Not a booking: a job assigned to someone, on its due date. Drawn in its
  /// own colours so it never reads as a hire.
  task,
}

/// One booking on the calendar. Plain data: no dependency on the host app's
/// entities, so the host maps its own bookings into this type.
@immutable
class TimeboardEvent {
  const TimeboardEvent({
    required this.id,
    required this.customer,
    required this.start,
    this.end,
    this.equipment = '',
    this.bookingNo,
    this.type = '',
    this.status = TimeboardBookingStatus.confirmed,
    this.timePending = false,
    this.allDay = false,
    this.monthLabel,
  });

  final String id;
  final String customer;
  final String equipment;

  /// Shown under the customer name in the agenda, e.g. "Booking #1048".
  final String? bookingNo;

  /// "Pickup" / "Return" (free text, shown as given).
  final String type;
  final TimeboardBookingStatus status;
  final DateTime start;

  /// Defaults to one hour after [start].
  final DateTime? end;

  /// No time slot yet: the week/day views pin it to the top of the timeline
  /// instead of placing it by [start].
  final bool timePending;
  final bool allDay;

  /// Overrides the one-line month chip text.
  final String? monthLabel;

  /// Has no slot on the hour grid: shown in the all-day strip instead.
  bool get isUntimed => allDay || timePending;

  String get title => equipment.isEmpty ? customer : '$customer · $equipment';

  DateTime get effectiveEnd => end ?? start.add(const Duration(hours: 1));

  /// First calendar day the event touches.
  DateTime get firstDay => dateOnly(start);

  /// Last calendar day the event touches. An event ending exactly at
  /// midnight does not spill onto the next day.
  DateTime get lastDay {
    final last = dateOnly(effectiveEnd.subtract(const Duration(minutes: 1)));
    final first = firstDay;
    return last.isBefore(first) ? first : last;
  }

  /// True when any part of the event falls on [day].
  bool occursOn(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(firstDay) && !d.isAfter(lastDay);
  }
}
