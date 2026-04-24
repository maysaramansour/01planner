import 'package:flutter/material.dart';
import 'package:dabab_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/habit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_badge.dart';
import 'habit_edit_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => HabitEditScreen(existing: habit)),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: HabitService().watchCompletions(),
        builder: (context, Box<HabitCompletion> _, __) {
          final streak = HabitService().streakFor(habit.id);
          final today = DateTime.now();
          final start = today.subtract(const Duration(days: 89));
          final completions =
              HabitService().completionsInRange(habit.id, start, today);
          final completedSet = completions
              .map((d) => HabitService().dateIso(d))
              .toSet();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.streak,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  StreakBadge(streak: streak),
                ],
              ),
              const SizedBox(height: 24),
              _Heatmap(start: start, end: today, completedSet: completedSet),
              if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(l.notes,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Text(habit.notes!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final Set<String> completedSet;

  const _Heatmap({
    required this.start,
    required this.end,
    required this.completedSet,
  });

  @override
  Widget build(BuildContext context) {
    final days = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(last)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((d) {
        final iso = HabitService().dateIso(d);
        final done = completedSet.contains(iso);
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done
                ? AppPalette.tertiary
                : AppPalette.surfaceVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    );
  }
}
