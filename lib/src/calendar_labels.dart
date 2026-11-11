import 'calendar_models.dart';

String _more(int n) => '+$n more';

/// Every user-visible string. Defaults are English; pass a translated
/// instance to localise without touching the package.
class TimeboardLabels {
  const TimeboardLabels({
    this.today = 'Today',
    this.month = 'Month',
    this.week = 'Week',
    this.day = 'Day',
    this.agenda = 'Agenda',
    this.filters = 'Filters',
    this.newBooking = 'New booking',
    this.noBookings = 'No bookings',
    this.allDay = 'ALL DAY',
    this.noAllDayBookings = 'No all-day bookings',
    this.timePending = 'Time pending',
    this.currentTime = 'Current time',
    this.yearLabel = 'Year',
    this.confirm = 'Confirm',
    this.reset = 'Reset',
    this.cancel = 'Cancel',
    this.pickDate = 'Pick a date',
    this.agendaDay = 'DAY',
    this.agendaTime = 'TIME',
    this.agendaBooking = 'BOOKING',
    this.agendaEquipment = 'EQUIPMENT',
    this.agendaType = 'TYPE',
    this.agendaStatus = 'STATUS',
    this.am = 'AM',
    this.pm = 'PM',
    this.moreLabel = _more,
    this.use24Hour = false,
    this.statuses = const {
      TimeboardBookingStatus.confirmed: 'Confirmed',
      TimeboardBookingStatus.out: 'Out',
      TimeboardBookingStatus.returned: 'Returned',
      TimeboardBookingStatus.draft: 'Draft',
      TimeboardBookingStatus.conflict: 'Conflict',
      TimeboardBookingStatus.overdue: 'Overdue',
      TimeboardBookingStatus.cancelled: 'Cancelled',
      TimeboardBookingStatus.task: 'Task',
    },
    this.monthNames = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    this.monthNamesShort = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    // Index 0 = Monday (matches DateTime.weekday - 1).
    this.weekdayNames = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
    this.weekdayShort = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
    // Index 0 = Monday. Two letters, for the date picker's column heads.
    this.weekdayMin = const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
  });

  final String today;
  final String month;
  final String week;
  final String day;
  final String agenda;
  final String filters;
  final String newBooking;
  final String noBookings;
  final String allDay;
  final String noAllDayBookings;
  final String timePending;
  final String currentTime;
  final String yearLabel;
  final String confirm;
  final String reset;
  final String cancel;

  /// Tooltip on the toolbar title, which opens the date picker.
  final String pickDate;
  final String agendaDay;
  final String agendaTime;
  final String agendaBooking;
  final String agendaEquipment;
  final String agendaType;
  final String agendaStatus;
  final String am;
  final String pm;
  final String Function(int count) moreLabel;

  /// "14:30" instead of "2:30 PM" everywhere a time is shown.
  final bool use24Hour;
  final Map<TimeboardBookingStatus, String> statuses;
  final List<String> monthNames;
  final List<String> monthNamesShort;
  final List<String> weekdayNames;
  final List<String> weekdayShort;
  final List<String> weekdayMin;

  String viewName(TimeboardView v) => switch (v) {
    TimeboardView.month => month,
    TimeboardView.week => week,
    TimeboardView.day => day,
    TimeboardView.agenda => agenda,
  };

  String statusName(TimeboardBookingStatus s) => statuses[s] ?? s.name;

  String monthName(DateTime d) => monthNames[d.month - 1];
  String monthShort(DateTime d) => monthNamesShort[d.month - 1];
  String weekdayName(DateTime d) => weekdayNames[d.weekday - 1];
  String weekdayAbbr(DateTime d) => weekdayShort[d.weekday - 1];

  String _meridiem(DateTime t) => t.hour < 12 ? am : pm;

  int _hour12(DateTime t) => t.hour % 12 == 0 ? 12 : t.hour % 12;

  String _mm(DateTime t) => t.minute.toString().padLeft(2, '0');

  String _hm(DateTime t) => use24Hour
      ? '${t.hour.toString().padLeft(2, '0')}:${_mm(t)}'
      : '${_hour12(t)}:${_mm(t)}';

  /// "9:00 AM", or "09:00" with [use24Hour].
  String time(DateTime t) => use24Hour ? _hm(t) : '${_hm(t)} ${_meridiem(t)}';

  /// "9:00 – 9:30 AM", or "10:00 AM – 2:00 PM" when the meridiem differs.
  String timeRange(DateTime start, DateTime end) {
    if (use24Hour) return '${_hm(start)} – ${_hm(end)}';
    if (_meridiem(start) == _meridiem(end)) {
      return '${_hm(start)} – ${_hm(end)} ${_meridiem(end)}';
    }
    return '${time(start)} – ${time(end)}';
  }

  /// Toolbar title for the given view and focused date.
  String title(
    TimeboardView view,
    DateTime focus,
    DateTime weekStart, {
    int agendaDays = 7,
  }) {
    switch (view) {
      case TimeboardView.month:
        return '${monthName(focus)} ${focus.year}';
      case TimeboardView.week:
        final end = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
        );
        if (weekStart.month == end.month && weekStart.year == end.year) {
          return '${weekStart.day}–${end.day} ${monthName(end)} ${end.year}';
        }
        return '${weekStart.day} ${monthShort(weekStart)} – '
            '${end.day} ${monthShort(end)} ${end.year}';
      case TimeboardView.day:
        return '${weekdayName(focus)}, ${focus.day} ${monthName(focus)} '
            '${focus.year}';
      case TimeboardView.agenda:
        final end = DateTime(
          focus.year,
          focus.month,
          focus.day + agendaDays - 1,
        );
        if (focus.month == end.month) {
          return '${monthShort(focus)} ${focus.day} – ${end.day}, ${end.year}';
        }
        return '${monthShort(focus)} ${focus.day} – '
            '${monthShort(end)} ${end.day}, ${end.year}';
    }
  }
}
