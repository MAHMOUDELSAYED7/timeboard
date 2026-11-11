import 'calendar_models.dart';
import 'calendar_utils.dart';

/// A multi-day event is indexed on at most this many days, so one bad
/// `end` (year 9999) cannot allocate millions of entries.
const _maxSpanDays = 400;

/// Events bucketed by day, built once per events list.
///
/// The views used to filter the whole list for every cell they drew (42 times
/// for a month). With the index each lookup is a single map read, and the
/// per-day lists are already sorted.
class TimeboardEventIndex {
  TimeboardEventIndex(List<TimeboardEvent> events)
    : source = events,
      _count = events.length {
    for (final e in events) {
      var day = e.firstDay;
      final last = e.lastDay;
      for (var n = 0; n < _maxSpanDays && !day.isAfter(last); n++) {
        (_byDay[_key(day)] ??= []).add(e);
        day = addDays(day, 1);
      }
    }
    for (final list in _byDay.values) {
      list.sort(_byStart);
    }
  }

  final List<TimeboardEvent> source;
  final int _count;
  final Map<int, List<TimeboardEvent>> _byDay = {};

  /// False once the host passes a different list (or grows/shrinks the same
  /// one). Mutating a list in place without changing its length is not seen:
  /// pass a new list when the bookings change.
  bool isFor(List<TimeboardEvent> events) =>
      identical(source, events) && _count == events.length;

  /// Events touching [day], earliest first. Do not modify the result.
  List<TimeboardEvent> on(DateTime day) =>
      _byDay[_key(day)] ?? const <TimeboardEvent>[];

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static int _byStart(TimeboardEvent a, TimeboardEvent b) {
    final c = a.start.compareTo(b.start);
    // Dart's sort is not stable: tie-break so the order never flickers.
    return c != 0 ? c : a.id.compareTo(b.id);
  }
}
