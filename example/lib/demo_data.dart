import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';

/// Bookings placed around the real "today", so every demo opens on data.
List<TimeboardEvent> buildDemoEvents() {
  final t = DateTime.now();
  DateTime at(int dayOffset, int h, [int m = 0]) =>
      DateTime(t.year, t.month, t.day + dayOffset, h, m);

  var n = 1000;
  TimeboardEvent ev(
    String customer,
    String equipment,
    int day,
    int hour, {
    int? endHour,
    String type = 'Pickup',
    TimeboardBookingStatus status = TimeboardBookingStatus.confirmed,
    bool timePending = false,
  }) {
    n++;
    return TimeboardEvent(
      id: 'e$n',
      customer: customer,
      equipment: equipment,
      bookingNo: 'Booking #$n',
      type: type,
      status: status,
      timePending: timePending,
      start: at(day, hour),
      end: endHour == null ? null : at(day, endHour),
    );
  }

  return [
    ev('Ahmed Hassan', 'Laptop + docking station', 0, 10, endHour: 12),
    ev(
      'Nour Khaled',
      'Wireless headphones',
      0,
      9,
      endHour: 10,
      type: 'Return',
      status: TimeboardBookingStatus.returned,
    ),
    ev(
      'Tarek Samir',
      'Monitor 27"',
      0,
      14,
      type: 'Return',
      status: TimeboardBookingStatus.out,
    ),
    ev(
      'Salma Adel',
      'Mechanical keyboard',
      0,
      17,
      status: TimeboardBookingStatus.draft,
    ),
    ev(
      'Overlap A',
      'Desk lamp',
      0,
      10,
      endHour: 11,
      status: TimeboardBookingStatus.conflict,
    ),
    ev('No time yet', 'Monitor arm', 0, 0, timePending: true),
    ev('Mariam Youssef', 'Office chair', 1, 9, endHour: 11),
    ev(
      'Layla Mostafa',
      'Standing desk',
      2,
      13,
      type: 'Return',
      status: TimeboardBookingStatus.overdue,
    ),
    ev(
      'Dina Fathy',
      'Starter bundle',
      3,
      11,
      status: TimeboardBookingStatus.cancelled,
    ),
    ev('Karim Ali', 'Printer', -1, 15, status: TimeboardBookingStatus.conflict),
    ev('Karim Ali', 'Tablet', -2, 10, endHour: 12),
    ev(
      'Assigned job',
      'Restock shelf',
      4,
      9,
      status: TimeboardBookingStatus.task,
    ),
    for (var i = 0; i < 4; i++)
      ev('Busy day ${i + 1}', 'Webcam', 6, 9 + i, endHour: 10 + i),
    TimeboardEvent(
      id: 'multi',
      customer: 'Dina Trading',
      equipment: 'Office setup',
      start: at(5, 9),
      end: at(8, 18),
    ),
    TimeboardEvent(
      id: 'allday',
      customer: 'Office move',
      equipment: 'Full set',
      allDay: true,
      start: at(1, 0),
      end: at(2, 0),
    ),
  ];
}

Future<void> showEventDialog(BuildContext context, TimeboardEvent e) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(e.customer),
        content: Text(
          [
            if (e.bookingNo != null) e.bookingNo!,
            if (e.equipment.isNotEmpty) e.equipment,
            '${e.type.isEmpty ? 'Booking' : e.type} · ${e.status.name}',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
}
