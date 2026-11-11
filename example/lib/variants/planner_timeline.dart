import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';

import '../demo_data.dart';

/// 3 · Planner timeline: week and day only, working hours 8-20 at 90px per
/// hour, 24-hour clock, Arabic labels, Saturday first, bookings coloured by
/// kind of product instead of by status, and a static "now" dot.
class PlannerTimeline extends StatelessWidget {
  const PlannerTimeline({super.key});

  static final _events = buildDemoEvents();

  static const _options = TimeboardOptions(
    views: [TimeboardView.week, TimeboardView.day],
    weekendDays: {DateTime.friday},
    dayStartHour: 8,
    dayEndHour: 20,
    hourHeight: 90,
    scrollToNow: false,
    animateNowIndicator: false,
    showFilters: false,
  );

  static const _labels = TimeboardLabels(
    use24Hour: true,
    today: 'اليوم',
    week: 'أسبوع',
    day: 'يوم',
    newBooking: 'حجز جديد',
    allDay: 'طوال اليوم',
    timePending: 'الوقت غير محدد',
    currentTime: 'الآن',
    pickDate: 'اختر تاريخًا',
    monthNames: [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ],
    monthNamesShort: [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ],
    weekdayNames: [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ],
    weekdayShort: ['اثن', 'ثلا', 'أرب', 'خمس', 'جمع', 'سبت', 'أحد'],
    weekdayMin: ['اث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'],
  );

  /// Product category from the equipment text: a stand-in for a real field.
  static (Color, Color) _palette(TimeboardEvent e, bool dark) {
    final q = e.equipment.toLowerCase();
    final (
      Color light,
      Color deep,
    ) = q.contains('laptop') || q.contains('monitor') || q.contains('tablet')
        ? (const Color(0xFFDCE8FF), const Color(0xFF1D4ED8))
        : q.contains('chair') || q.contains('desk')
        ? (const Color(0xFFFFEFC7), const Color(0xFF92580A))
        : q.contains('headphones') ||
              q.contains('keyboard') ||
              q.contains('webcam')
        ? (const Color(0xFFD9F5E6), const Color(0xFF15703E))
        : (const Color(0xFFE9E5F5), const Color(0xFF5B3FA0));
    return dark
        ? (
            Color.alphaBlend(
              deep.withValues(alpha: 0.35),
              const Color(0xFF191919),
            ),
            light,
          )
        : (light, deep);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = TimeboardTheme.fromSeed(
      const Color(0xFF6D4AFF),
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Timeboard(
        events: _events,
        theme: theme,
        labels: _labels,
        options: _options,
        initialView: TimeboardView.week,
        firstWeekday: DateTime.saturday,
        eventColors: (e, _) {
          final (fill, text) = _palette(e, dark);
          return TimeboardStatusColors(fill: fill, text: text);
        },
        onNewBooking: () => showSnack(context, 'حجز جديد'),
        onEventTap: (e) => showEventDialog(context, e),
      ),
    );
  }
}
