import 'package:flutter/material.dart';

import 'calendar_labels.dart';
import 'calendar_theme.dart';
import 'calendar_utils.dart';
import 'calendar_widgets.dart';

const _yearItemHeight = 44.0;
const _yearColumnWidth = 84.0;
const _bodyHeight = 352.0;

/// A month grid with a year column beside it.
///
/// Picking a day calls [onDateSelected] straight away. With
/// [showConfirmButton] the day is only marked, and [onDateSelected] fires when
/// *Confirm* is pressed, so the choice can still be changed.
///
/// The months run from [firstDate] to [lastDate] (1900 to 2100 by default),
/// days outside that range are disabled, and the year column lists the same
/// range.
class TimeboardDatePicker extends StatefulWidget {
  const TimeboardDatePicker({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.showConfirmButton = false,
    this.confirmLabel,
    this.showResetButton = false,
    this.onCancel,
    this.theme,
    this.labels = const TimeboardLabels(),
    this.firstWeekday = DateTime.sunday,
    this.today,
    this.width = 520,
  });

  /// The day shown as selected, and the month the picker opens on. Defaults
  /// to today. Clamped into [firstDate]..[lastDate].
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  final ValueChanged<DateTime> onDateSelected;

  /// Off by default: selecting a day completes the pick.
  final bool showConfirmButton;

  /// Defaults to [TimeboardLabels.confirm].
  final String? confirmLabel;

  /// Optional, off by default: an icon button at the top that puts the
  /// selection (and the month shown) back to [initialDate]. It does not call
  /// [onDateSelected].
  final bool showResetButton;

  /// Optional: an icon button at the top that closes the picker without
  /// choosing. Shown only when this is given.
  final VoidCallback? onCancel;

  /// Defaults to the light or dark preset, following the surrounding [Theme].
  final TimeboardTheme? theme;
  final TimeboardLabels labels;

  /// First column of the grid (`DateTime.monday`..`DateTime.sunday`).
  final int firstWeekday;

  /// The day ringed as "today". Defaults to the device date.
  final DateTime? today;

  /// Preferred width. It narrows to fit a smaller parent.
  final double width;

  @override
  State<TimeboardDatePicker> createState() => _TimeboardDatePickerState();
}

class _TimeboardDatePickerState extends State<TimeboardDatePicker> {
  late final DateTime _first;
  late final DateTime _last;
  late final DateTime _today;
  late DateTime _selected;
  late DateTime _shown; // first day of the month on screen
  late final PageController _pages;
  late final ScrollController _years;

  /// The page being settled on. Arrow clicks add to it rather than to the
  /// page last drawn, so two quick clicks go two months, not one.
  late int _target;

  @override
  void initState() {
    super.initState();
    _first = dateOnly(widget.firstDate ?? DateTime(1900));
    _last = dateOnly(widget.lastDate ?? DateTime(2100, 12, 31));
    assert(!_last.isBefore(_first), 'lastDate is before firstDate');
    _today = dateOnly(widget.today ?? DateTime.now());
    _selected = _clamp(dateOnly(widget.initialDate ?? _today));
    _shown = DateTime(_selected.year, _selected.month);
    _target = _indexOf(_shown);
    _pages = PageController(initialPage: _target);
    _years = ScrollController(initialScrollOffset: _yearOffset(_shown.year));
  }

  @override
  void dispose() {
    _pages.dispose();
    _years.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime d) =>
      d.isBefore(_first) ? _first : (d.isAfter(_last) ? _last : d);

  /// Page index of a month: months since the first month in range.
  int _indexOf(DateTime month) =>
      (month.year - _first.year) * 12 + (month.month - _first.month);

  DateTime _monthAt(int index) => DateTime(_first.year, _first.month + index);

  int get _monthCount => _indexOf(DateTime(_last.year, _last.month)) + 1;

  /// Scroll offset that leaves [year] with two years above it.
  double _yearOffset(int year) =>
      ((year - _first.year - 2) * _yearItemHeight).clamp(0.0, double.infinity);

  bool _enabled(DateTime d) => !d.isBefore(_first) && !d.isAfter(_last);

  void _goToIndex(int index, {bool animate = true}) {
    final i = index.clamp(0, _monthCount - 1);
    _target = i;
    if (animate) {
      _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _pages.jumpToPage(i);
    }
  }

  void _onPageChanged(int index) {
    // A swipe lands here without going through [_goToIndex].
    if (!_pages.position.isScrollingNotifier.value) _target = index;
    final month = _monthAt(index);
    final yearChanged = month.year != _shown.year;
    setState(() => _shown = month);
    // Keep the year column on the year being looked at.
    if (yearChanged && _years.hasClients) {
      _years.animateTo(
        _yearOffset(month.year).clamp(0.0, _years.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pickYear(int year) {
    // Same month in the chosen year, held inside the allowed range.
    var target = DateTime(year, _shown.month);
    final lo = DateTime(_first.year, _first.month);
    final hi = DateTime(_last.year, _last.month);
    if (target.isBefore(lo)) target = lo;
    if (target.isAfter(hi)) target = hi;
    // A jump, not an animation: a decade is 120 pages.
    _goToIndex(_indexOf(target), animate: false);
  }

  void _reset() {
    final initial = _clamp(dateOnly(widget.initialDate ?? _today));
    setState(() => _selected = initial);
    _goToIndex(_indexOf(DateTime(initial.year, initial.month)));
  }

  void _pickDay(DateTime day) {
    if (!_enabled(day)) return;
    setState(() => _selected = day);
    if (day.year != _shown.year || day.month != _shown.month) {
      _goToIndex(_indexOf(DateTime(day.year, day.month)));
    }
    if (!widget.showConfirmButton) widget.onDateSelected(day);
  }

  @override
  Widget build(BuildContext context) {
    final t =
        widget.theme ??
        (Theme.of(context).brightness == Brightness.dark
            ? TimeboardTheme.dark
            : TimeboardTheme.light);
    final l = widget.labels;

    final body = SizedBox(
      height: _bodyHeight,
      child: Row(
        children: [
          Expanded(child: _calendarSide(t, l)),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: t.borderGrid,
          ),
          SizedBox(width: _yearColumnWidth, child: _yearSide(t, l)),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.surfaceCanvas,
          border: Border.all(color: t.borderDefault),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showResetButton || widget.onCancel != null) ...[
              _topBar(t, l),
              const SizedBox(height: 8),
            ],
            body,
            if (widget.showConfirmButton) ...[
              const SizedBox(height: 20),
              _confirm(t, l),
            ],
          ],
        ),
      ),
    );
  }

  /// Reset at the start, cancel at the end, as icon buttons.
  Widget _topBar(TimeboardTheme t, TimeboardLabels l) {
    return Row(
      children: [
        if (widget.showResetButton)
          _IconAction(
            icon: Icons.refresh_rounded,
            tooltip: l.reset,
            theme: t,
            onTap: _reset,
          ),
        const Spacer(),
        if (widget.onCancel != null)
          _IconAction(
            icon: Icons.close_rounded,
            tooltip: l.cancel,
            theme: t,
            onTap: widget.onCancel!,
          ),
      ],
    );
  }

  Widget _confirm(TimeboardTheme t, TimeboardLabels l) {
    return Material(
      color: t.actionPrimary,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onDateSelected(_selected),
        child: Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            widget.confirmLabel ?? l.confirm,
            style: t.text(
              16,
              FontWeight.w600,
              t.contentOnAction,
              lineHeight: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ── month side ────────────────────────────────────────────────────────

  Widget _calendarSide(TimeboardTheme t, TimeboardLabels l) {
    final index = _indexOf(_shown);
    return Column(
      children: [
        Row(
          children: [
            _NavButton(
              icon: 'chevron_left',
              theme: t,
              enabled: index > 0,
              onTap: () => _goToIndex(_target - 1),
            ),
            Expanded(
              child: Text(
                '${l.monthName(_shown)} ${_shown.year}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.text(
                  18,
                  FontWeight.w600,
                  t.contentPrimary,
                  lineHeight: 24,
                ),
              ),
            ),
            _NavButton(
              icon: 'chevron_right',
              theme: t,
              enabled: index < _monthCount - 1,
              onTap: () => _goToIndex(_target + 1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      l.weekdayMin[(widget.firstWeekday - 1 + i) % 7],
                      maxLines: 1,
                      style: t.text(
                        12,
                        FontWeight.w500,
                        t.contentMuted,
                        lineHeight: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _monthCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) => _MonthGrid(
              month: _monthAt(i),
              firstWeekday: widget.firstWeekday,
              selected: _selected,
              today: _today,
              theme: t,
              isEnabled: _enabled,
              onPick: _pickDay,
            ),
          ),
        ),
      ],
    );
  }

  // ── year side ─────────────────────────────────────────────────────────

  Widget _yearSide(TimeboardTheme t, TimeboardLabels l) {
    final count = _last.year - _first.year + 1;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Center(
            child: Text(
              l.yearLabel,
              style: t.text(
                14,
                FontWeight.w500,
                t.contentPrimary,
                lineHeight: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            controller: _years,
            itemCount: count,
            itemExtent: _yearItemHeight,
            itemBuilder: (context, i) {
              final year = _first.year + i;
              final isShown = year == _shown.year;
              final isThisYear = year == _today.year;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: isShown ? t.actionPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _pickYear(year),
                    child: Center(
                      child: Text(
                        '$year',
                        style: t.text(
                          14,
                          isShown ? FontWeight.w600 : FontWeight.w400,
                          isShown
                              ? t.contentOnAction
                              : (isThisYear ? t.contentBrand : t.contentMuted),
                          lineHeight: 20,
                        ),
                      ),
                    ),
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

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final TimeboardTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Icon(icon, size: 20, color: theme.contentPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.theme,
  });

  final String icon;
  final bool enabled;
  final VoidCallback onTap;
  final TimeboardTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(child: TimeboardIcon(icon, color: t.contentMuted)),
          ),
        ),
      ),
    );
  }
}

/// Six rows of seven days, including the tail of the previous month and the
/// head of the next so the grid never changes height between months.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.firstWeekday,
    required this.selected,
    required this.today,
    required this.theme,
    required this.isEnabled,
    required this.onPick,
  });

  final DateTime month;
  final int firstWeekday;
  final DateTime selected;
  final DateTime today;
  final TimeboardTheme theme;
  final bool Function(DateTime) isEnabled;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final start = startOfWeek(DateTime(month.year, month.month), firstWeekday);

    return Column(
      children: [
        for (var w = 0; w < 6; w++)
          Expanded(
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(child: _cell(addDays(start, w * 7 + d))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(DateTime day) {
    final t = theme;
    final inMonth = day.month == month.month;
    final isSelected = isSameDay(day, selected);
    final isToday = isSameDay(day, today);
    final enabled = isEnabled(day);

    final Color text;
    if (isSelected) {
      text = t.contentOnAction;
    } else if (!enabled) {
      text = t.contentMuted.withValues(alpha: 0.4);
    } else if (!inMonth) {
      text = t.contentMuted;
    } else if (isToday) {
      text = t.contentBrand;
    } else {
      text = t.contentPrimary;
    }

    return Center(
      child: LayoutBuilder(
        builder: (context, c) {
          final size = (c.maxHeight < c.maxWidth ? c.maxHeight : c.maxWidth)
              .clamp(0.0, 40.0);
          return SizedBox(
            width: size,
            height: size,
            child: Material(
              color: isSelected ? t.actionPrimary : Colors.transparent,
              shape: CircleBorder(
                // Today is ringed, unless it is the selected day (filled).
                side: isToday && !isSelected
                    ? BorderSide(color: t.actionPrimary, width: 1.5)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => onPick(day) : null,
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: t.text(
                      14,
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                      text,
                      lineHeight: 20,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Opens [TimeboardDatePicker] in a dialog. Resolves to the chosen day, or null if
/// it is dismissed. The dialog is laid out left to right, like the calendar.
Future<DateTime?> showTimeboardDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  bool showConfirmButton = false,
  String? confirmLabel,
  bool showResetButton = false,
  bool showCancelButton = false,
  TimeboardTheme? theme,
  TimeboardLabels labels = const TimeboardLabels(),
  int firstWeekday = DateTime.sunday,
  DateTime? today,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: TimeboardDatePicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          showConfirmButton: showConfirmButton,
          confirmLabel: confirmLabel,
          showResetButton: showResetButton,
          onCancel: showCancelButton
              ? () => Navigator.of(dialogContext).pop()
              : null,
          theme: theme,
          labels: labels,
          firstWeekday: firstWeekday,
          today: today,
          onDateSelected: (d) => Navigator.of(dialogContext).pop(d),
        ),
      ),
    ),
  );
}
