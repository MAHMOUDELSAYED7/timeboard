import 'package:flutter/material.dart';

import 'agenda_view.dart';
import 'calendar_controller.dart';
import 'calendar_labels.dart';
import 'calendar_models.dart';
import 'calendar_options.dart';
import 'calendar_scope.dart';
import 'calendar_theme.dart';
import 'calendar_toolbar.dart';
import 'calendar_utils.dart';
import 'timeboard_date_picker.dart';
import 'day_view.dart';
import 'event_index.dart';
import 'month_view.dart';
import 'week_view.dart';

/// The calendar content area: toolbar + the active view. It does not include
/// the app sidebar or top bar, so the host places it inside its own shell.
///
/// Everything is adjustable: colours and radii through [theme], text through
/// [labels], layout and behaviour through [options], and how a booking looks
/// through [eventBuilder] / [eventColors].
class Timeboard extends StatefulWidget {
  const Timeboard({
    super.key,
    required this.events,
    this.controller,
    this.initialView = TimeboardView.month,
    this.initialDate,
    this.firstWeekday = DateTime.sunday,
    this.theme,
    this.labels = const TimeboardLabels(),
    this.options = const TimeboardOptions(),
    this.padding,
    this.backgroundColor,
    this.onNewBooking,
    this.onFilters,
    this.onEventTap,
    this.onDayTap,
    this.onViewChanged,
    this.onDateChanged,
    this.eventBuilder,
    this.eventColors,
    this.enableDatePicker = true,
  });

  /// The bookings. Pass a **new list** when they change: the calendar indexes
  /// the list once and reuses that index for as long as it is the same
  /// instance, which is what keeps scrolling and navigation cheap.
  final List<TimeboardEvent> events;

  /// Optional: lets the host change view/date programmatically. Not disposed
  /// by the calendar when supplied. When given, [initialView], [initialDate]
  /// and [firstWeekday] are ignored: the controller owns them.
  final TimeboardController? controller;

  final TimeboardView initialView;
  final DateTime? initialDate;

  /// First column of the month grid and week (`DateTime.monday`..`sunday`).
  final int firstWeekday;

  /// Defaults to [TimeboardTheme.dark] / [TimeboardTheme.light] following
  /// the surrounding [Theme] brightness.
  final TimeboardTheme? theme;

  /// Hoist it (a `const` or a field) rather than building it in `build`: an
  /// identical instance lets the calendar skip rebuilding its views.
  final TimeboardLabels labels;
  final TimeboardOptions options;

  /// Space around the toolbar and panel. Defaults to 32 x 24 on tablets and
  /// desktops and 12 on phones. Pass [EdgeInsets.zero] when the host page
  /// already has its own gutter.
  final EdgeInsetsGeometry? padding;

  /// Behind the toolbar and the panel's corners. Defaults to the theme's
  /// canvas; pass [Colors.transparent] to let the host page show through.
  final Color? backgroundColor;
  final VoidCallback? onNewBooking;
  final VoidCallback? onFilters;
  final ValueChanged<TimeboardEvent>? onEventTap;
  final ValueChanged<DateTime>? onDayTap;

  /// Called after the user (or the host's controller) changes the view.
  final ValueChanged<TimeboardView>? onViewChanged;

  /// Called after the focused date moves to another day.
  final ValueChanged<DateTime>? onDateChanged;

  /// Draws a booking your way in the month, all-day and timeline slots.
  final TimeboardEventBuilder? eventBuilder;

  /// Chooses a booking's colours, e.g. by customer or equipment type.
  final TimeboardEventColors? eventColors;

  /// Tapping the date in the toolbar opens a [TimeboardDatePicker] and moves the
  /// calendar to the day chosen.
  final bool enableDatePicker;

  @override
  State<Timeboard> createState() => _TimeboardState();
}

class _TimeboardState extends State<Timeboard> {
  TimeboardController? _own;
  late TimeboardController _attached;
  late TimeboardEventIndex _index;
  late TimeboardView _lastView;
  late DateTime _lastDate;

  TimeboardController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = _makeOwn();
    _index = TimeboardEventIndex(widget.events);
    _attach();
  }

  TimeboardController _makeOwn() => TimeboardController(
    view: widget.initialView,
    initialDate: widget.initialDate,
    firstWeekday: widget.firstWeekday,
  );

  void _attach() {
    _attached = _controller..addListener(_reportChanges);
    _lastView = _attached.view;
    _lastDate = _attached.focusedDate;
  }

  /// Tells the host about view and date changes, whoever made them.
  void _reportChanges() {
    final c = _attached;
    if (c.view != _lastView) {
      _lastView = c.view;
      widget.onViewChanged?.call(c.view);
    }
    if (!isSameDay(c.focusedDate, _lastDate)) {
      _lastDate = c.focusedDate;
      widget.onDateChanged?.call(c.focusedDate);
    }
  }

  @override
  void didUpdateWidget(Timeboard old) {
    super.didUpdateWidget(old);
    if (!_index.isFor(widget.events)) {
      _index = TimeboardEventIndex(widget.events);
    }

    _attached.removeListener(_reportChanges);
    if (widget.controller == null) {
      _own ??= _makeOwn();
    } else {
      _own?.dispose();
      _own = null;
    }
    _attach();
  }

  @override
  void dispose() {
    _attached.removeListener(_reportChanges);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.theme ??
        (Theme.of(context).brightness == Brightness.dark
            ? TimeboardTheme.dark
            : TimeboardTheme.light);
    final o = widget.options;

    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < o.compactBelow;
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final c = _controller;
            return TimeboardScope(
              compact: compact,
              onSelectDay: compact ? c.setFocusedDate : null,
              theme: theme,
              labels: widget.labels,
              options: o,
              today: c.today,
              clock: c.clock,
              firstWeekday: c.firstWeekday,
              index: _index,
              onEventTap: widget.onEventTap,
              onDayTap: widget.onDayTap,
              eventBuilder: widget.eventBuilder,
              eventColors: widget.eventColors,
              child: ColoredBox(
                color: widget.backgroundColor ?? theme.surfaceCanvas,
                child: Padding(
                  padding:
                      widget.padding ??
                      (compact
                          ? const EdgeInsets.all(12)
                          : const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            )),
                  child: Column(
                    children: [
                      if (o.showToolbar) ...[
                        TimeboardToolbar(
                          title: widget.labels.title(
                            c.view,
                            c.focusedDate,
                            c.weekStart,
                            agendaDays: o.agendaDays,
                          ),
                          view: c.view,
                          onToday: c.goToToday,
                          onPrevious: c.previous,
                          onNext: c.next,
                          onViewChanged: c.setView,
                          onTitleTap: widget.enableDatePicker
                              ? () => _pickDate(context, theme, c)
                              : null,
                          onFilters: widget.onFilters,
                          onNewBooking: widget.onNewBooking,
                        ),
                        SizedBox(height: o.toolbarGap),
                      ],
                      _panel(theme, c),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TimeboardTheme theme,
    TimeboardController c,
  ) async {
    final picked = await showTimeboardDatePicker(
      context,
      initialDate: c.focusedDate,
      theme: theme,
      labels: widget.labels,
      firstWeekday: c.firstWeekday,
      today: c.today,
    );
    if (picked != null) c.setFocusedDate(picked);
  }

  Widget _panel(TimeboardTheme theme, TimeboardController c) {
    final body = switch (c.view) {
      TimeboardView.month => TimeboardMonthView(focusedDate: c.focusedDate),
      TimeboardView.week => TimeboardWeekView(weekStart: c.weekStart),
      TimeboardView.day => TimeboardDayView(day: c.focusedDate),
      TimeboardView.agenda => TimeboardAgendaView(startDate: c.focusedDate),
    };

    // The border is a foreground decoration, painted over the children. As
    // part of `decoration` it sits under them, and the clip is the outer
    // rounded rect, so the first row's fill painted over the border at the
    // corners and left dark, uneven corner pixels.
    final radius = BorderRadius.circular(theme.panelRadius);
    final panel = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surfaceSubtle,
        borderRadius: radius,
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: theme.borderDefault),
        borderRadius: radius,
      ),
      child: body,
    );

    // The agenda hugs its rows; the grid views fill the remaining height.
    return c.view == TimeboardView.agenda
        ? Flexible(child: panel)
        : Expanded(child: panel);
  }
}
