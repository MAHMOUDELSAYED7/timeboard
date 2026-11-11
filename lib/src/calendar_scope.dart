import 'package:flutter/widgets.dart';

import 'calendar_labels.dart';
import 'calendar_models.dart';
import 'calendar_options.dart';
import 'calendar_theme.dart';
import 'calendar_utils.dart';
import 'event_index.dart';

/// Carries the resolved theme, labels, options, "today", the event index and
/// the host's callbacks to every view, so they stay constructor-light and
/// independent of each other.
class TimeboardScope extends InheritedWidget {
  const TimeboardScope({
    super.key,
    required this.theme,
    required this.labels,
    required this.options,
    required this.today,
    required this.clock,
    required this.firstWeekday,
    required this.index,
    this.compact = false,
    this.onSelectDay,
    this.onEventTap,
    this.onDayTap,
    this.eventBuilder,
    this.eventColors,
    required super.child,
  });

  final TimeboardTheme theme;
  final TimeboardLabels labels;
  final TimeboardOptions options;
  final DateTime today;

  /// The calendar's notion of "now" (injectable for tests).
  final DateTime Function() clock;
  final int firstWeekday;
  final TimeboardEventIndex index;

  /// Phone-sized: narrower than `options.compactBelow`.
  final bool compact;

  /// Compact month: a tap on a day selects it (the list below shows its
  /// bookings) before [onDayTap] is told.
  final ValueChanged<DateTime>? onSelectDay;
  final ValueChanged<TimeboardEvent>? onEventTap;
  final ValueChanged<DateTime>? onDayTap;
  final TimeboardEventBuilder? eventBuilder;
  final TimeboardEventColors? eventColors;

  DateTime get now => clock();

  bool isWeekend(DateTime day) => options.weekendDays.contains(day.weekday);

  bool isToday(DateTime day) => isSameDay(day, today);

  /// Fill and text colours for [event]: the host's resolver, else the theme's.
  TimeboardStatusColors colorsOf(
    TimeboardEvent event, {
    bool solidDraft = false,
  }) {
    final custom = eventColors;
    if (custom != null) return custom(event, theme);
    return solidDraft && event.status == TimeboardBookingStatus.draft
        ? theme.draftSolid
        : theme.statusColors(event.status);
  }

  /// The host's widget for [event] in [slot], or [fallback] when there is no
  /// builder or it returns null.
  Widget eventWidget(
    BuildContext context,
    TimeboardEvent event,
    TimeboardEventSlot slot,
    Widget Function() fallback,
  ) => eventBuilder?.call(context, event, slot) ?? fallback();

  static TimeboardScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TimeboardScope>();
    assert(scope != null, 'TimeboardScope missing: use Timeboard.');
    return scope!;
  }

  @override
  bool updateShouldNotify(TimeboardScope old) =>
      theme != old.theme ||
      !identical(labels, old.labels) ||
      options != old.options ||
      today != old.today ||
      clock != old.clock ||
      firstWeekday != old.firstWeekday ||
      !identical(index, old.index) ||
      compact != old.compact ||
      onSelectDay != old.onSelectDay ||
      onEventTap != old.onEventTap ||
      onDayTap != old.onDayTap ||
      eventBuilder != old.eventBuilder ||
      eventColors != old.eventColors;
}
