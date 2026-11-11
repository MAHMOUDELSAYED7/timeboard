import 'package:flutter/material.dart';

import 'calendar_models.dart';
import 'calendar_scope.dart';
import 'calendar_widgets.dart';
import 'time_grid.dart';

class TimeboardDayView extends StatelessWidget {
  const TimeboardDayView({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final s = TimeboardScope.of(context);
    final t = s.theme;
    final isToday = s.isToday(day);
    final gutter = s.compact ? 60.0 : 96.0;
    final allDay = [
      for (final e in s.index.on(day))
        if (e.isUntimed) e,
    ];

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: EdgeInsets.symmetric(horizontal: s.compact ? 16 : 24),
          decoration: BoxDecoration(
            color: t.surfaceCanvas,
            border: Border(bottom: BorderSide(color: t.borderGrid)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? t.actionPrimary : t.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: t.text(
                    16,
                    FontWeight.w700,
                    isToday ? t.contentOnAction : t.contentPrimary,
                    lineHeight: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Flexible: a long weekday at a large text size ellipsises
              // instead of overflowing a narrow phone.
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.labels.weekdayName(day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        15,
                        FontWeight.w600,
                        t.contentPrimary,
                        lineHeight: 21,
                      ),
                    ),
                    Text(
                      '${s.labels.monthName(day)} ${day.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        12,
                        FontWeight.w400,
                        t.contentMuted,
                        lineHeight: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: t.surfaceCanvas,
            border: Border(bottom: BorderSide(color: t.borderGrid)),
          ),
          child: Row(
            children: [
              Container(
                width: gutter,
                padding: EdgeInsets.only(right: s.compact ? 6 : 12),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: t.borderGrid)),
                ),
                child: Text(
                  s.labels.allDay,
                  style: t.text(
                    10,
                    FontWeight.w600,
                    t.contentMuted,
                    lineHeight: 14,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.compact ? 12 : 32,
                    vertical: 12,
                  ),
                  child: allDay.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s.labels.noAllDayBookings,
                            style: t.text(
                              12,
                              FontWeight.w400,
                              t.contentMuted,
                              lineHeight: 17,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final e in allDay)
                                TimeboardEventChip(
                                  event: e,
                                  slot: TimeboardEventSlot.allDayChip,
                                  horizontalPadding: 12,
                                  verticalPadding: 6,
                                  fontSize: 12,
                                  lineHeight: 15.6,
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TimeboardTimeGrid(
            days: [day],
            gutterWidth: gutter,
            gutterRightPadding: s.compact ? 6 : 12,
            columnDividers: false,
          ),
        ),
      ],
    );
  }
}
