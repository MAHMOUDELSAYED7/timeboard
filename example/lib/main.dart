import 'package:flutter/material.dart';

import 'variants/minimal_month.dart';
import 'variants/ops_dashboard.dart';
import 'variants/playground.dart';
import 'variants/planner_timeline.dart';

void main() => runApp(const DemoApp());

/// Four different configurations of the same package, one tab each.
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _mode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timeboard demo',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: DemoShell(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(
          () => _mode = _mode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      ),
    );
  }
}

class DemoShell extends StatefulWidget {
  const DemoShell({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  static const _variants = <(String, IconData, Widget)>[
    ('Ops dashboard', Icons.dashboard_outlined, OpsDashboard()),
    ('Minimal month', Icons.calendar_view_month, MinimalMonth()),
    ('Planner timeline', Icons.view_timeline_outlined, PlannerTimeline()),
    ('Playground', Icons.tune, Playground()),
  ];

  int _index = 0;

  Widget _pages() => IndexedStack(
    // Keeps each variant's state when switching tabs.
    index: _index,
    children: [for (final (_, _, page) in _variants) page],
  );

  @override
  Widget build(BuildContext context) {
    // Phones get a bottom bar; tablets and desktops a side rail.
    final phone = MediaQuery.sizeOf(context).width < 700;
    final themeButton = IconButton(
      tooltip: 'Toggle theme',
      onPressed: widget.onToggleTheme,
      icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
    );

    if (phone) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_variants[_index].$1),
          actions: [themeButton],
        ),
        body: SafeArea(child: _pages()),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final (label, icon, _) in _variants)
              NavigationDestination(icon: Icon(icon), label: label),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) => setState(() => _index = i),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: themeButton,
                ),
              ),
              destinations: [
                for (final (label, icon, _) in _variants)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages()),
          ],
        ),
      ),
    );
  }
}
