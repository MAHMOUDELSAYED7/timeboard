import 'package:timeboard/timeboard.dart';

/// Fixtures matching the Figma frames (October 2026, "today" = 14 Oct).
/// For demos, previews and tests only.
class TimeboardSampleData {
  const TimeboardSampleData._();

  static final DateTime today = DateTime(2026, 10, 14);

  static List<TimeboardEvent> events() {
    DateTime d(int day, int h, [int m = 0]) => DateTime(2026, 10, day, h, m);
    const s = TimeboardBookingStatus.values;
    return [
      // Month-only context
      TimeboardEvent(
        id: 'm1',
        customer: 'Ahmed',
        equipment: 'Sony FX3',
        monthLabel: 'Ahmed · Sony FX3 · Pickup 10:00',
        type: 'Pickup',
        start: d(5, 10),
      ),
      for (var i = 0; i < 3; i++)
        TimeboardEvent(
          id: 'm1-$i',
          customer: 'Client ${i + 1}',
          equipment: 'Kit',
          start: d(5, 12 + i),
        ),
      TimeboardEvent(
        id: 'm2',
        customer: 'Mariam',
        equipment: 'Lighting package',
        monthLabel: 'Mariam · Lighting package · Out',
        status: s[1],
        start: d(8, 9),
      ),
      for (var i = 0; i < 5; i++)
        TimeboardEvent(
          id: 'm3-$i',
          customer: 'Nour Films',
          equipment: 'Audio kit',
          monthLabel: 'Nour Films · Audio kit · Draft',
          status: TimeboardBookingStatus.draft,
          timePending: i == 0,
          start: d(11, 9 + i),
        ),
      TimeboardEvent(
        id: 'm4',
        customer: 'Dina Studio',
        equipment: 'Production package',
        start: d(19, 9),
        end: d(19, 12),
      ),
      TimeboardEvent(
        id: 'm5',
        customer: 'Conflict',
        equipment: '2 equipment items',
        status: TimeboardBookingStatus.conflict,
        start: d(23, 10),
      ),
      TimeboardEvent(
        id: 'm6',
        customer: 'Karim',
        equipment: 'Camera kit',
        monthLabel: 'Karim · Camera kit · Out',
        status: TimeboardBookingStatus.out,
        start: d(25, 9),
      ),
      TimeboardEvent(
        id: 'm7',
        customer: 'Salma',
        monthLabel: 'Salma · Pickup 14:30',
        start: d(29, 14, 30),
      ),

      // Week / day: Wed 14 Oct, 6 PM return.
      TimeboardEvent(
        id: 'w1',
        customer: 'Tarek',
        equipment: 'Cinema lenses',
        type: 'Return',
        status: TimeboardBookingStatus.returned,
        start: d(14, 18),
        end: d(14, 19, 30),
      ),

      // Agenda: 14–19 Oct.
      TimeboardEvent(
        id: 'a1',
        customer: 'Nour Khaled',
        bookingNo: 'Booking #1044',
        equipment: 'Rode Wireless Pro ×2, Sennheiser MKH 416',
        type: 'Return',
        status: TimeboardBookingStatus.returned,
        start: d(14, 9),
        end: d(14, 9, 30),
      ),
      TimeboardEvent(
        id: 'a2',
        customer: 'Ahmed Hassan',
        bookingNo: 'Booking #1048',
        equipment: 'Sony FX3 + FE 24-70mm GM',
        type: 'Pickup',
        start: d(14, 10),
        end: d(14, 14),
      ),
      TimeboardEvent(
        id: 'a3',
        customer: 'Tarek Samir',
        bookingNo: 'Booking #1041',
        equipment: 'Canon EOS R5, RF 70-200mm f/2.8',
        type: 'Return',
        status: TimeboardBookingStatus.out,
        start: d(14, 14, 30),
        end: d(14, 15, 30),
      ),
      TimeboardEvent(
        id: 'a4',
        customer: 'Salma Adel',
        bookingNo: 'Booking #1052',
        equipment: 'DJI RS 3 Pro gimbal',
        type: 'Pickup',
        status: TimeboardBookingStatus.draft,
        start: d(14, 17),
        end: d(14, 17, 30),
      ),
      TimeboardEvent(
        id: 'a5',
        customer: 'Mariam Youssef',
        bookingNo: 'Booking #1049',
        equipment: 'Aputure 600d Pro lighting kit',
        type: 'Pickup',
        start: d(16, 9, 30),
        end: d(16, 10, 30),
      ),
      TimeboardEvent(
        id: 'a6',
        customer: 'Layla Mostafa',
        bookingNo: 'Booking #1045',
        equipment: 'Sony FX6, 3× V-mount batteries',
        type: 'Return',
        status: TimeboardBookingStatus.out,
        start: d(16, 13),
        end: d(16, 14),
      ),
      TimeboardEvent(
        id: 'a7',
        customer: 'Dina Fathy',
        bookingNo: 'Booking #1050',
        equipment: 'Wedding package · 2 bodies, 3 lenses',
        type: 'Pickup',
        start: d(17, 11),
        end: d(17, 12),
      ),
      TimeboardEvent(
        id: 'a8',
        customer: 'Karim Ali',
        bookingNo: 'Booking #1051',
        equipment: 'Canon C70 · also booked on #1047',
        type: 'Pickup',
        status: TimeboardBookingStatus.conflict,
        start: d(17, 15),
        end: d(17, 16),
      ),
      TimeboardEvent(
        id: 'a9',
        customer: 'Karim Ali',
        bookingNo: 'Booking #1053',
        equipment: 'Sony A7 IV kit, 2 lenses',
        type: 'Pickup',
        status: TimeboardBookingStatus.draft,
        start: d(19, 10),
        end: d(19, 12),
      ),
    ];
  }
}
