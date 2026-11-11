import 'package:flutter/material.dart';

import 'calendar_labels.dart';
import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_widgets.dart';

/// Below this the toolbar drops to two rows (navigation, then the switcher).
const _compactBelow = 960.0;

/// Below this the design's full single row no longer fits: the tabs narrow
/// and "Filters" keeps only its icon.
const _fullFrom = 1240.0;

/// Below this "New booking" keeps only its icon.
const _iconOnlyBelow = 640.0;

class TimeboardToolbar extends StatefulWidget {
  const TimeboardToolbar({
    super.key,
    required this.title,
    required this.view,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
    required this.onViewChanged,
    this.onTitleTap,
    this.onFilters,
    this.onNewBooking,
  });

  final String title;
  final TimeboardView view;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<TimeboardView> onViewChanged;

  /// Makes the date title a button (the calendar uses it to open the picker).
  final VoidCallback? onTitleTap;
  final VoidCallback? onFilters;
  final VoidCallback? onNewBooking;

  @override
  State<TimeboardToolbar> createState() => _TimeboardToolbarState();
}

class _TimeboardToolbarState extends State<TimeboardToolbar> {
  // Measuring every candidate title costs dozens of text layouts. The result
  // only changes with these inputs, so it is computed once per combination
  // instead of on every rebuild and every layout pass.
  Object? _slotKey;
  double _slotWidth = 0;

  double _titleSlot(BuildContext context, TimeboardScope s, TextStyle style) {
    final key = (
      s.labels,
      widget.view,
      style,
      MediaQuery.textScalerOf(context),
    );
    if (key != _slotKey) {
      _slotKey = key;
      _slotWidth = _titleSlotWidth(context, s.labels, widget.view, style);
    }
    return _slotWidth;
  }

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final l = s.labels;
    final o = s.options;

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final compact = width < _compactBelow;
        final full = width >= _fullFrom;

        final titleSize = s.compact
            ? 16.0
            : (full ? 22.0 : (compact ? 18.0 : 20.0));
        final titleStyle = t.text(
          titleSize,
          FontWeight.w600,
          t.contentPrimary,
          lineHeight: titleSize * 1.4,
        );
        // A fixed slot, as wide as the longest title this view can show, with
        // the title centred in it. Otherwise the arrows ride on the text and
        // move every time the month name gets longer or shorter. A window too
        // narrow for the slot scales the text down instead of overflowing.
        final titleSlot = SizedBox(
          width: _titleSlot(context, s, titleStyle),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.title, maxLines: 1, style: titleStyle),
          ),
        );
        final titleText = widget.onTitleTap == null
            ? titleSlot
            : Tooltip(
                message: l.pickDate,
                child: InkWell(
                  onTap: widget.onTitleTap,
                  borderRadius: BorderRadius.circular(t.chipRadius),
                  child: titleSlot,
                ),
              );

        final nav = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconButton(icon: 'chevron_left', onTap: widget.onPrevious),
            SizedBox(width: compact ? 8 : 12),
            Flexible(child: titleText),
            SizedBox(width: compact ? 8 : 12),
            _IconButton(icon: 'chevron_right', onTap: widget.onNext),
          ],
        );

        final switcher = o.showViewSwitcher && o.views.length > 1
            ? _Switcher(
                views: o.views,
                view: widget.view,
                onChanged: widget.onViewChanged,
                tabWidth: full ? 92 : 76,
                stretch: compact,
              )
            : null;

        final today = o.showTodayButton
            ? _ActionButton(
                onTap: widget.onToday,
                fill: t.surfaceSubtle,
                border: t.borderDefault,
                height: 40,
                label: l.today,
                labelStyle: t.text(
                  13,
                  FontWeight.w600,
                  t.contentPrimary,
                  lineHeight: 18,
                ),
              )
            : null;

        final filters = o.showFilters
            ? _ActionButton(
                onTap: widget.onFilters,
                fill: t.surfaceSubtle,
                border: t.borderDefault,
                icon: 'filter',
                iconColor: t.contentPrimary,
                label: full ? l.filters : null,
                tooltip: l.filters,
                labelStyle: t.text(
                  16,
                  FontWeight.w600,
                  t.contentPrimary,
                  lineHeight: 18,
                ),
              )
            : null;

        final newBooking = o.showNewBooking
            ? _ActionButton(
                onTap: widget.onNewBooking,
                fill: t.actionPrimary,
                icon: 'plus',
                iconColor: t.contentOnAction,
                label: width < _iconOnlyBelow ? null : l.newBooking,
                tooltip: l.newBooking,
                labelStyle: t.text(
                  16,
                  FontWeight.w600,
                  t.contentOnAction,
                  lineHeight: 18,
                ),
              )
            : null;

        // The title is the one flexible piece: a long range ("28 Oct – 3 Nov
        // 2026") ellipsises rather than pushing the buttons off the edge.
        Widget row(List<Widget?> parts, {double gap = 12}) {
          final present = parts.whereType<Widget>().toList();
          return Row(
            children: [
              for (var i = 0; i < present.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                present[i],
              ],
            ],
          );
        }

        final middle = Expanded(child: Center(child: nav));

        if (s.compact) {
          // Phone: the date and the two icon actions on top, Today and the
          // view tabs on the row below, so nothing has to shrink below a
          // comfortable tap size.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row([middle, filters, newBooking], gap: 8),
              if (today != null || switcher != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ?today,
                    if (today != null && switcher != null)
                      const SizedBox(width: 8),
                    if (switcher != null) Expanded(child: switcher),
                  ],
                ),
              ],
            ],
          );
        }
        if (compact) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row([today, middle, filters, newBooking]),
              if (switcher != null) ...[const SizedBox(height: 12), switcher],
            ],
          );
        }
        return row([today, middle, switcher, filters, newBooking]);
      },
    );
  }
}

/// Width of the widest title [view] can produce, so the slot never changes
/// from one month (or week, or day) to the next.
double _titleSlotWidth(
  BuildContext context,
  TimeboardLabels l,
  TimeboardView view,
  TextStyle style,
) {
  final scaler = MediaQuery.textScalerOf(context);

  double measure(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  String widest(Iterable<String> options) {
    var best = options.first;
    var bestWidth = measure(best);
    for (final o in options.skip(1)) {
      final w = measure(o);
      if (w > bestWidth) {
        best = o;
        bestWidth = w;
      }
    }
    return best;
  }

  // "28" is among the widest two-digit pairs, so every date fits.
  const d = '28';
  const y = '2026';
  final month = widest(l.monthNames);
  final short = widest(l.monthNamesShort);
  final weekday = widest(l.weekdayNames);

  final candidates = switch (view) {
    TimeboardView.month => [for (final m in l.monthNames) '$m $y'],
    TimeboardView.week => ['$d–$d $month $y', '$d $short – $d $short $y'],
    TimeboardView.day => ['$weekday, $d $month $y'],
    TimeboardView.agenda => ['$short $d – $d, $y', '$short $d – $short $d, $y'],
  };
  // A little slack for kerning and digits that are not all the same width.
  return candidates.map(measure).reduce((a, b) => a > b ? a : b) + 6;
}

class _Switcher extends StatelessWidget {
  const _Switcher({
    required this.views,
    required this.view,
    required this.onChanged,
    required this.tabWidth,
    required this.stretch,
  });

  final List<TimeboardView> views;
  final TimeboardView view;
  final ValueChanged<TimeboardView> onChanged;
  final double tabWidth;

  /// Fill the available width with equal tabs (the compact, second-row case).
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;

    final tabs = [
      for (final v in views)
        _ViewTab(
          label: s.labels.viewName(v),
          active: v == view,
          width: stretch ? null : tabWidth,
          onTap: () => onChanged(v),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        border: Border.all(color: t.borderDefault),
        borderRadius: BorderRadius.circular(t.controlRadius + 2),
      ),
      child: Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            stretch ? Expanded(child: tabs[i]) : tabs[i],
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.fill,
    required this.labelStyle,
    this.border,
    this.onTap,
    this.height = 48,
    this.icon,
    this.iconColor,
    this.label,
    this.tooltip,
  });

  final Color fill;
  final Color? border;
  final VoidCallback? onTap;
  final double height;
  final String? icon;
  final Color? iconColor;
  final String? label;
  final String? tooltip;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final iconOnly = label == null && icon != null;
    final radius = TimeboardScope.of(context).theme.controlRadius;

    final button = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          height: height,
          width: iconOnly ? height : null,
          padding: iconOnly
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) TimeboardIcon(icon!, color: iconColor!),
              if (icon != null && label != null) const SizedBox(width: 8),
              if (label != null) Text(label!, maxLines: 1, style: labelStyle),
            ],
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = TimeboardScope.of(context).theme;
    return Material(
      color: t.surfaceCanvas,
      borderRadius: BorderRadius.circular(t.controlRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: TimeboardIcon(icon, color: t.contentMuted)),
        ),
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({
    required this.label,
    required this.active,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool active;
  final double? width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = TimeboardScope.of(context).theme;
    return Material(
      color: active ? t.surfaceBrandSubtle : Colors.transparent,
      borderRadius: BorderRadius.circular(t.chipRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          height: 40,
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: active
                ? t.text(14, FontWeight.w600, t.contentBrand)
                : t.text(14, FontWeight.w500, t.contentSecondary),
          ),
        ),
      ),
    );
  }
}
