import 'package:flutter/foundation.dart';

import 'calendar_models.dart';
import 'calendar_utils.dart';

/// Holds the active view and focused date. Create one to drive the calendar
/// from outside (e.g. a "go to booking" action); otherwise [Timeboard]
/// makes its own.
class TimeboardController extends ChangeNotifier {
  TimeboardController({
    TimeboardView view = TimeboardView.month,
    DateTime? initialDate,
    this.firstWeekday = DateTime.sunday,
    DateTime Function()? now,
  }) : assert(
         firstWeekday >= DateTime.monday && firstWeekday <= DateTime.sunday,
         'firstWeekday must be DateTime.monday..DateTime.sunday',
       ),
       _now = now ?? DateTime.now,
       _view = view {
    _focused = dateOnly(initialDate ?? _now());
  }

  final int firstWeekday;
  final DateTime Function() _now;

  TimeboardView _view;
  late DateTime _focused;

  TimeboardView get view => _view;
  DateTime get focusedDate => _focused;
  DateTime get now => _now();
  DateTime Function() get clock => _now;
  DateTime get today => dateOnly(_now());
  DateTime get weekStart => startOfWeek(_focused, firstWeekday);

  void setView(TimeboardView v) {
    if (v == _view) return;
    _view = v;
    notifyListeners();
  }

  void setFocusedDate(DateTime d) {
    final day = dateOnly(d);
    if (isSameDay(day, _focused)) return;
    _focused = day;
    notifyListeners();
  }

  void goToToday() => setFocusedDate(today);

  void next() => _step(1);
  void previous() => _step(-1);

  void _step(int dir) {
    switch (_view) {
      case TimeboardView.month:
        _focused = DateTime(_focused.year, _focused.month + dir, 1);
      case TimeboardView.week:
      case TimeboardView.agenda:
        _focused = addDays(_focused, 7 * dir);
      case TimeboardView.day:
        _focused = addDays(_focused, dir);
    }
    notifyListeners();
  }
}
