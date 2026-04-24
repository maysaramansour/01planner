import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../models/goal.dart';
import '../models/task.dart';
import '../services/goal_service.dart';
import '../services/task_service.dart';
import '../widgets/empty_state.dart';
import 'goal_detail_screen.dart';
import 'goal_edit_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: GoalService().watchAll(),
        builder: (context, Box<Goal> _, __) {
          return ValueListenableBuilder(
            valueListenable: TaskService().watchAll(),
            builder: (context, Box<Task> _, __) {
              final goals = GoalService().all();
              if (goals.isEmpty) {
                return EmptyState(
                    icon: Icons.flag_outlined, message: l.noGoals);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: goals.length,
                itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoalEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final progress = GoalService().progressFor(goal.id);
    final target = goal.targetDate == null
        ? null
        : intl.DateFormat.yMMMd(lang).format(goal.targetDate!);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(goal.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (target != null)
                    Row(
                      children: [
                        Icon(Icons.flag, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(target,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(cs.tertiary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${progress.completed}/${progress.total} • ${(progress.fraction * 100).round()}%',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
