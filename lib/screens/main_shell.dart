import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';

import '../widgets/new_task_sheet.dart';
import 'ai_screen.dart';
import 'inbox_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = const [
      InboxScreen(),
      TodayScreen(),
      AIScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton(
              onPressed: () => showNewTaskSheet(context),
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.inbox_outlined),
              activeIcon: const Icon(Icons.inbox),
              label: l.inbox),
          BottomNavigationBarItem(
              icon: const Icon(Icons.view_timeline_outlined),
              activeIcon: const Icon(Icons.view_timeline),
              label: l.timeline),
          BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome_outlined),
              activeIcon: const Icon(Icons.auto_awesome),
              label: l.ai),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: l.settings),
        ],
      ),
    );
  }
}
