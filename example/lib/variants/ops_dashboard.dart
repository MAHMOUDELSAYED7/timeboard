import 'package:timeboard/timeboard.dart';
import 'package:flutter/material.dart';

import '../demo_data.dart';

/// 1 · Ops dashboard: the package as it ships (default theme and options),
/// driven from outside through a [TimeboardController], with every callback
/// reported in a log line.
class OpsDashboard extends StatefulWidget {
  const OpsDashboard({super.key});

  @override
  State<OpsDashboard> createState() => _OpsDashboardState();
}

class _OpsDashboardState extends State<OpsDashboard> {
  final _controller = TimeboardController();
  final _events = buildDemoEvents();
  String _log = 'Tap an event, a day or a button.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _say(String s) => setState(() => _log = s);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrolls sideways on a phone instead of wrapping to rows.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _controller
                          ..setView(TimeboardView.week)
                          ..setFocusedDate(
                            DateTime.now().add(const Duration(days: 14)),
                          ),
                        child: const Text('Week in 2 weeks'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _controller.setView(TimeboardView.agenda),
                        child: const Text('Agenda'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _controller.goToToday,
                        child: const Text('Back to today'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(_log, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
        Expanded(
          child: Timeboard(
            controller: _controller,
            events: _events,
            onNewBooking: () => _say('onNewBooking'),
            onFilters: () => _say('onFilters'),
            onEventTap: (e) {
              _say('onEventTap: ${e.title}');
              showEventDialog(context, e);
            },
            onDayTap: (d) {
              _say('onDayTap: ${d.toIso8601String().substring(0, 10)}');
              _controller
                ..setFocusedDate(d)
                ..setView(TimeboardView.day);
            },
            onViewChanged: (v) => _say('onViewChanged: ${v.name}'),
            onDateChanged: (d) =>
                _say('onDateChanged: ${d.toIso8601String().substring(0, 10)}'),
          ),
        ),
      ],
    );
  }
}
