DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// First day of the week containing [d]. [firstWeekday] uses
/// [DateTime.monday]..[DateTime.sunday].
DateTime startOfWeek(DateTime d, int firstWeekday) {
  final diff = (d.weekday - firstWeekday + 7) % 7;
  return addDays(d, -diff);
}
