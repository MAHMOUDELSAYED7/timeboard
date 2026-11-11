import 'package:flutter/foundation.dart';

import 'calendar_models.dart';

/// Behaviour and layout switches. Colours and radii live in
/// [TimeboardTheme], text in [TimeboardLabels]; everything here is
/// `const`-friendly and compared by value, so passing a fresh instance does
/// not rebuild the calendar.
@immutable
class TimeboardOptions {
  const TimeboardOptions({
    this.views = TimeboardView.values,
    this.weekendDays = const {DateTime.friday, DateTime.saturday},
    this.dayStartHour = 0,
    this.dayEndHour = 24,
    this.hourHeight = 64,
    this.maxChipsPerDay = 2,
    this.monthChipHeight = 28,
    this.minMonthRowHeight = 136,
    this.agendaDays = 7,
    this.showToolbar = true,
    this.showTodayButton = true,
    this.showViewSwitcher = true,
    this.showFilters = true,
    this.showNewBooking = true,
    this.showNowIndicator = true,
    this.animateNowIndicator = true,
    this.scrollToNow = true,
    this.toolbarGap = 20,
    this.compactBelow = 600,
    this.compactWeekColumnWidth = 88,
  }) : assert(dayStartHour >= 0 && dayStartHour < 24),
       assert(dayEndHour > dayStartHour && dayEndHour <= 24),
       assert(hourHeight > 0),
       assert(maxChipsPerDay >= 0),
       assert(agendaDays >= 1);

  /// Views offered in the switcher, in order. Hide a view by leaving it out.
  final List<TimeboardView> views;

  /// Days shaded as days off in the month grid and week header
  /// (`DateTime.monday`..`DateTime.sunday`). Defaults to Friday and Saturday;
  /// pass an empty set for a business that is open every day.
  final Set<int> weekendDays;

  /// Hour range of the week and day timelines (start inclusive): the whole
  /// day by default.
  final int dayStartHour;
  final int dayEndHour;

  /// Height of one hour on the timelines. Taller shows more of each booking;
  /// shorter fits more of the day on screen.
  final double hourHeight;

  /// Bookings a month cell or all-day strip shows before "+N more".
  final int maxChipsPerDay;
  final double monthChipHeight;

  /// Below this a month row stops shrinking and the grid scrolls instead.
  final double minMonthRowHeight;

  /// How many days the agenda lists, starting at the focused date.
  final int agendaDays;

  final bool showToolbar;
  final bool showTodayButton;
  final bool showViewSwitcher;
  final bool showFilters;
  final bool showNewBooking;

  /// The green "now" dot on today's timeline column.
  final bool showNowIndicator;

  /// Pulse the dot. Off, it is static and the idle calendar draws no frames.
  final bool animateNowIndicator;

  /// Open the timelines at the current hour instead of at [dayStartHour].
  final bool scrollToNow;

  /// Space between the toolbar and the panel.
  final double toolbarGap;

  /// Narrower than this (phones) every view switches to its compact layout:
  /// the month shows dots and a list for the selected day, the week scrolls
  /// sideways, the agenda stacks each booking, and the toolbar uses icons.
  /// Tablets and desktops stay above it. Pass 0 to never go compact.
  final double compactBelow;

  /// Width of one day column in the compact week, which scrolls sideways
  /// when seven of them do not fit.
  final double compactWeekColumnWidth;

  int get hourCount => dayEndHour - dayStartHour;

  TimeboardOptions copyWith({
    List<TimeboardView>? views,
    Set<int>? weekendDays,
    int? dayStartHour,
    int? dayEndHour,
    double? hourHeight,
    int? maxChipsPerDay,
    double? monthChipHeight,
    double? minMonthRowHeight,
    int? agendaDays,
    bool? showToolbar,
    bool? showTodayButton,
    bool? showViewSwitcher,
    bool? showFilters,
    bool? showNewBooking,
    bool? showNowIndicator,
    bool? animateNowIndicator,
    bool? scrollToNow,
    double? toolbarGap,
    double? compactBelow,
    double? compactWeekColumnWidth,
  }) => TimeboardOptions(
    views: views ?? this.views,
    weekendDays: weekendDays ?? this.weekendDays,
    dayStartHour: dayStartHour ?? this.dayStartHour,
    dayEndHour: dayEndHour ?? this.dayEndHour,
    hourHeight: hourHeight ?? this.hourHeight,
    maxChipsPerDay: maxChipsPerDay ?? this.maxChipsPerDay,
    monthChipHeight: monthChipHeight ?? this.monthChipHeight,
    minMonthRowHeight: minMonthRowHeight ?? this.minMonthRowHeight,
    agendaDays: agendaDays ?? this.agendaDays,
    showToolbar: showToolbar ?? this.showToolbar,
    showTodayButton: showTodayButton ?? this.showTodayButton,
    showViewSwitcher: showViewSwitcher ?? this.showViewSwitcher,
    showFilters: showFilters ?? this.showFilters,
    showNewBooking: showNewBooking ?? this.showNewBooking,
    showNowIndicator: showNowIndicator ?? this.showNowIndicator,
    animateNowIndicator: animateNowIndicator ?? this.animateNowIndicator,
    scrollToNow: scrollToNow ?? this.scrollToNow,
    toolbarGap: toolbarGap ?? this.toolbarGap,
  );

  @override
  bool operator ==(Object other) =>
      other is TimeboardOptions &&
      listEquals(other.views, views) &&
      setEquals(other.weekendDays, weekendDays) &&
      other.dayStartHour == dayStartHour &&
      other.dayEndHour == dayEndHour &&
      other.hourHeight == hourHeight &&
      other.maxChipsPerDay == maxChipsPerDay &&
      other.monthChipHeight == monthChipHeight &&
      other.minMonthRowHeight == minMonthRowHeight &&
      other.agendaDays == agendaDays &&
      other.showToolbar == showToolbar &&
      other.showTodayButton == showTodayButton &&
      other.showViewSwitcher == showViewSwitcher &&
      other.showFilters == showFilters &&
      other.showNewBooking == showNewBooking &&
      other.showNowIndicator == showNowIndicator &&
      other.animateNowIndicator == animateNowIndicator &&
      other.scrollToNow == scrollToNow &&
      other.toolbarGap == toolbarGap &&
      other.compactBelow == compactBelow &&
      other.compactWeekColumnWidth == compactWeekColumnWidth;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(views),
    Object.hashAllUnordered(weekendDays),
    dayStartHour,
    dayEndHour,
    hourHeight,
    maxChipsPerDay,
    monthChipHeight,
    minMonthRowHeight,
    agendaDays,
    showToolbar,
    showTodayButton,
    showViewSwitcher,
    showFilters,
    showNewBooking,
    Object.hash(
      showNowIndicator,
      animateNowIndicator,
      scrollToNow,
      toolbarGap,
      compactBelow,
      compactWeekColumnWidth,
    ),
  );
}
