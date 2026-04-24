import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/habit_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/streak_badge.dart';
import 'habit_detail_screen.dart';
import 'habit_edit_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: HabitService().watchAll(),
        builder: (context, Box<Habit> _, __) {
          return ValueListenableBuilder(
            valueListenable: HabitService().watchCompletions(),
            builder: (context, Box<HabitCompletion> _, __) {
              final habits = HabitService().all();
              if (habits.isEmpty) {
                return EmptyState(
                    icon: Icons.repeat_outlined, message: l.noHabits);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: habits.length,
                itemBuilder: (_, i) =>
                    _HabitTile(habit: habits[i]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HabitEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final svc = HabitService();
    final today = DateTime.now();
    final done = svc.isDoneOn(habit.id, today);
    final scheduled = svc.isScheduledOn(habit, today);
    final streak = svc.streakFor(habit.id);
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: done ? cs.tertiary : cs.onSurfaceVariant,
                  size: 28,
                ),
                onPressed: scheduled
                    ? () async {
                        if (done) {
                          await svc.unmarkDone(habit.id, today);
                        } else {
                          await svc.markDone(habit.id, today);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.reminderHour.toString().padLeft(2, '0')}:${habit.reminderMinute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StreakBadge(streak: streak),
            ],
          ),
        ),
      ),
    );
  }
}
