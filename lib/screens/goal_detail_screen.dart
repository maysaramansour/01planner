import 'package:flutter/material.dart';
import 'package:one_planner/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../models/task.dart';
import '../services/ai_config.dart';
import '../services/ai_service.dart';
import '../services/goal_service.dart';
import '../services/task_service.dart';
import '../widgets/plan_preview_sheet.dart';
import '../widgets/task_tile.dart';
import 'goal_edit_screen.dart';
import 'task_edit_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  bool _generating = false;

  Future<void> _generateWithAI() async {
    final l = AppLocalizations.of(context)!;
    if (!AIConfig().enabled.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiDisabledHint)),
      );
      return;
    }
    setState(() => _generating = true);
    final action = await AIService().extractTasksForGoal(
      goalId: widget.goal.id,
      goalTitle: widget.goal.title,
      goalDescription: widget.goal.description,
      targetDate: widget.goal.targetDate,
    );
    if (!mounted) {
      setState(() => _generating = false);
      return;
    }
    setState(() => _generating = false);
    if (action == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.aiUnavailable)),
      );
      return;
    }
    final committed = await showPlanPreviewSheet(context, action);
    if (committed == null) return;
    // Re-stamp targetGoalId onto the filtered action before executing.
    final enrichedData = {
      ...committed.data,
      'targetGoalId': widget.goal.id,
    };
    await _executeTasksPlan(AIAction(AIActionKind.plan, enrichedData));
  }

  Future<void> _executeTasksPlan(AIAction action) async {
    // We can't reach _executeAction on AIScreen from here; reuse the same
    // service calls inline. We only need the tasks path (no new goals/habits).
    final tasks = action.data['tasks'];
    if (tasks is! List) return;
    final goalId = action.data['targetGoalId'] as String? ?? widget.goal.id;
    int added = 0;
    for (final t in tasks) {
      if (t is! Map<String, dynamic>) continue;
      final title = (t['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) continue;
      final sRaw = t['scheduledStart'] as String?;
      final start = sRaw != null ? DateTime.tryParse(sRaw) : null;
      final subtasks = <String>[];
      if (t['subtasks'] is List) {
        for (final v in (t['subtasks'] as List)) {
          if (v is String && v.trim().isNotEmpty) {
            subtasks.add(v.startsWith('[') ? v : '[ ] $v');
          }
        }
      }
      await TaskService().add(Task(
        id: const Uuid().v4(),
        title: title,
        createdAt: DateTime.now(),
        scheduledStart: start,
        durationMinutes: t['durationMinutes'] is int
            ? t['durationMinutes'] as int
            : (start != null ? 30 : null),
        iconKey: kIconKeys.contains(t['iconKey'])
            ? t['iconKey'] as String
            : null,
        colorValue: kPaletteColors.first,
        notes: t['notes'] is String ? t['notes'] as String : null,
        subtasks: subtasks.isEmpty ? null : subtasks,
        reminderEnabled: start != null,
        reminderLeadMinutes: 10,
        goalId: goalId,
      ));
      added++;
    }
    if (mounted && added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n().aiCreatedPlan(0, 0, added))),
      );
    }
  }

  AppLocalizations l10n() => AppLocalizations.of(context)!;

  Future<void> _linkExistingTasks() async {
    final unlinked = TaskService()
        .all()
        .where((t) => t.goalId == null && !t.completed)
        .toList();
    if (unlinked.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n().noUnlinkedTasks)),
        );
      }
      return;
    }
    final selected = <String>{};
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: StatefulBuilder(
          builder: (ctx, setSt) {
            final cs = Theme.of(ctx).colorScheme;
            final l = AppLocalizations.of(ctx)!;
            final lang = Localizations.localeOf(ctx).languageCode;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l.linkExistingTasks,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: unlinked.length,
                    itemBuilder: (c, i) {
                      final t = unlinked[i];
                      final isSelected = selected.contains(t.id);
                      final when = t.scheduledStart == null
                          ? l.inbox
                          : intl.DateFormat.MMMd(lang)
                              .add_jm()
                              .format(t.scheduledStart!);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(when,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                        onChanged: (v) {
                          setSt(() {
                            if (v == true) {
                              selected.add(t.id);
                            } else {
                              selected.remove(t.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: Text(l.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: selected.isEmpty
                                ? null
                                : () =>
                                    Navigator.of(ctx).pop(selected.toSet()),
                            icon: const Icon(Icons.link),
                            label: Text(l.linkCount(selected.length)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (picked == null || picked.isEmpty) return;
    for (final id in picked) {
      final t = TaskService().all().firstWhere(
            (x) => x.id == id,
            orElse: () => Task(id: '', title: '', createdAt: DateTime.now()),
          );
      if (t.id.isEmpty) continue;
      t.goalId = widget.goal.id;
      await TaskService().update(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final goal = widget.goal;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => GoalEditScreen(existing: goal)),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: TaskService().watchAll(),
        builder: (context, Box<Task> _, __) {
          final tasks = TaskService().tasksForGoal(goal.id);
          final progress = GoalService().progressFor(goal.id);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                Text(goal.description!,
                    style: TextStyle(color: cs.onSurface, fontSize: 14)),
                const SizedBox(height: 16),
              ],
              if (goal.targetDate != null)
                Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '${l.targetDate}: ${intl.DateFormat.yMMMd(lang).format(goal.targetDate!)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 10,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(cs.tertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${(progress.fraction * 100).round()}%',
                      style: TextStyle(
                          color: cs.tertiary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(l.subtasks,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l.addSubtask),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              TaskEditScreen(prefillGoalId: goal.id)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Action row: Generate / Link
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generating ? null : _generateWithAI,
                      icon: _generating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.auto_awesome, color: cs.primary, size: 18),
                      label: Text(l.generateSubtasksAI,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(
                            color: cs.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _linkExistingTasks,
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(l.linkExistingTasks,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.checklist,
                          color: cs.onSurfaceVariant, size: 36),
                      const SizedBox(height: 8),
                      Text(l.noTasks,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...tasks.map((t) => TaskTile(
                      task: t,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => TaskEditScreen(existing: t)),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
