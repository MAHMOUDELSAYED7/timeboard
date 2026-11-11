# timeboard

Month / Week / Day / Agenda calendar for Flutter (desktop-first), with light and dark themes. No dependencies beyond Flutter.

```dart
Timeboard(
  events: bookings,                       // pass a NEW list when it changes
  onEventTap: (e) => open(e),
)
```

## What you can change

| Where | What |
|---|---|
| `Timeboard(...)` | `controller`, `initialView`, `initialDate`, `firstWeekday`, `padding`, `backgroundColor`, `enableDatePicker`, callbacks (`onEventTap`, `onDayTap`, `onNewBooking`, `onFilters`, `onViewChanged`, `onDateChanged`) |
| `theme: TimeboardTheme` | every colour, status colours, font, `panelRadius` / `chipRadius` / `controlRadius`; `copyWith(...)` and `TimeboardTheme.fromSeed(brandColor)` |
| `options: TimeboardOptions` | `views`, `weekendDays`, `dayStartHour` / `dayEndHour`, `hourHeight`, `maxChipsPerDay`, `monthChipHeight`, `minMonthRowHeight`, `agendaDays`, `show*` toolbar switches, `showNowIndicator`, `animateNowIndicator`, `scrollToNow`, `toolbarGap` |
| `labels: TimeboardLabels` | every string, month/day names, `use24Hour` |
| `eventColors` | colours per booking (by customer, gear type, ...) |
| `eventBuilder` | your own widget for a booking in the month / all-day / timeline slot; return null to keep the default |

## Phones, tablets, desktop

One widget, three layouts, chosen from the width the calendar is given (not the platform), so Android, iOS, iPad, foldables and resized desktop windows all behave the same.

| Width | Layout |
|---|---|
| below `options.compactBelow` (600) | **Phone**: icon-only actions, tabs on their own row; month = dots + list of the selected day (tap a day to select, tap it again for `onDayTap`); week scrolls sideways (`compactWeekColumnWidth`) and opens on today; agenda rows stack in two lines |
| 600 – 1240 | **Tablet**: two-row toolbar below 960, full month grid with chips, compact agenda columns below 860 |
| 1240+ | **Desktop**: single-row toolbar, full labels |

Large system text sizes are supported: headers and rows grow instead of overflowing. Pass `compactBelow: 0` to keep the tablet/desktop layout on every width.

## Performance notes

- Bookings are indexed by day once per list instance; views read a day with one map lookup.
- Hoist `labels` (use `const`) so the calendar can skip rebuilding when nothing changed. `theme` and `options` compare by value.
- Timeline grid lines are one `CustomPainter`; the "now" dot repaints in its own layer, and `animateNowIndicator: false` stops all idle frames.

See `example/` for four different configurations (`cd example && flutter run -d linux`).
