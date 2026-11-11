import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';

import '../demo_data.dart';

/// 2 · Minimal month: a month-only widget for a dashboard card. No toolbar
/// buttons beyond the date arrows, Monday first, Saturday and Sunday off,
/// square-ish teal styling, and a custom chip that shows a coloured dot and
/// the customer only.
class MinimalMonth extends StatelessWidget {
  const MinimalMonth({super.key});

  static final _events = buildDemoEvents();

  static const _options = TimeboardOptions(
    views: [TimeboardView.month],
    weekendDays: {DateTime.saturday, DateTime.sunday},
    maxChipsPerDay: 3,
    monthChipHeight: 22,
    minMonthRowHeight: 120,
    showTodayButton: false,
    showFilters: false,
    showNewBooking: false,
    toolbarGap: 8,
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = TimeboardTheme.fromSeed(
      const Color(0xFF0F9D8A),
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(panelRadius: 6, chipRadius: 4, controlRadius: 4);

    return Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 8 : 24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Timeboard(
          events: _events,
          theme: theme,
          options: _options,
          firstWeekday: DateTime.monday,
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          enableDatePicker: false,
          onEventTap: (e) => showEventDialog(context, e),
          eventBuilder: (context, event, slot) {
            if (slot != TimeboardEventSlot.monthChip) return null;
            final c = theme.statusColors(event.status);
            return InkWell(
              onTap: () => showEventDialog(context, event),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.text,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(
                        11,
                        FontWeight.w500,
                        theme.contentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
